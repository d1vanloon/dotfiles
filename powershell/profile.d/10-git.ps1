# Function for creating .gitignore file
function New-GitIgnore {
    param(
        [Parameter(Mandatory = $true)]
        [string]$token
    )
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/github/gitignore/refs/heads/main/$token.gitignore" |
        Select-Object -ExpandProperty content |
        Out-File -FilePath (Join-Path -Path $pwd -ChildPath ".gitignore") -Encoding ascii
}

# Helper function for creating new signed git tags
function New-GitSignedTag {
    param(
        [Parameter(Mandatory = $true)]
        [string]$tag_name
    )

    git tag -s -m "$tag_name" $tag_name
}

# Use FzF to enable fuzzy branch selection
function GitCheckoutFuzzy {
    param (
        [Parameter(Position = 0)]
        [string]
        $Query = ""
    )

    & git switch @(git for-each-ref --format='%(refname:short)' refs/heads refs/remotes | ForEach-Object {
            if ("$_".StartsWith('origin/')) {
                return "$_".Substring(7)
            }
            return $_
        } | Sort-Object -Unique | fzf --query="$Query" --preview="git log --ignore-missing --oneline -n 10 {1}")
}

function Get-JiraIssueTitle {
    param(
        [Parameter(Mandatory)]
        [string]$IssueKey
    )

    $baseUrl = $env:JIRA_BASE_URL
    $email = $env:JIRA_EMAIL
    $token = $env:JIRA_API_TOKEN

    if (-not $baseUrl -or -not $email -or -not $token) {
        throw "JIRA_BASE_URL, JIRA_EMAIL, and JIRA_API_TOKEN environment variables must be set."
    }

    $authBytes = [System.Text.Encoding]::UTF8.GetBytes("${email}:${token}")
    $authHeader = "Basic " + [Convert]::ToBase64String($authBytes)

    $headers = @{
        Authorization = $authHeader
        Accept        = "application/json"
    }

    $uri = "${baseUrl}/rest/agile/1.0/issue/${IssueKey}?fields=summary"

    try {
        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
    }
    catch {
        throw "Failed to retrieve Jira issue $IssueKey. $_"
    }

    $title = $response.fields.summary

    if (-not $title) {
        throw "Issue title not found for $IssueKey."
    }

    return $title
}

function New-JiraBranch {
    param(
        [Parameter(Mandatory)]
        [string]$IssueKey,
        [switch]$Feature
    )

    $title = Get-JiraIssueTitle -IssueKey $IssueKey

    # Normalize title for Git branch
    $normalizedTitle = $title.ToLower()
    $normalizedTitle = $normalizedTitle -replace '[^a-z0-9\s-]', ''
    $normalizedTitle = $normalizedTitle -replace '\s+', '-'
    $normalizedTitle = $normalizedTitle.Trim('-')

    $prefix = ""

    if ($Feature) {
        $prefix = "feature/"
    }

    $branchName = "${prefix}${IssueKey}-${normalizedTitle}"

    Write-Host "Creating and checking out branch '$branchName'..."

    git switch -c $branchName

    git push
}

function Get-GitWorktrees {
    git worktree list --porcelain | Where-Object { $_ -like 'worktree *' } | ForEach-Object {
        $path = $_ -replace 'worktree ', ''
        [System.IO.Path]::GetFileName($path)
    }
}

function Get-GitWorktreePathByName {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $WorktreeName
    )

    # Get all worktrees and their paths
    $worktrees = git worktree list --porcelain | Where-Object { $_ -like 'worktree *' }

    foreach ($entry in $worktrees) {
        $path = $entry -replace 'worktree ', ''
        if ([System.IO.Path]::GetFileName($path) -eq $WorktreeName) {
            return $path
        }
    }

    return $null
}

# Shared selection helper for git worktrees. If a name is provided it is returned
# unchanged; otherwise an interactive fzf selector is presented.
function Select-GitWorktreeName {
    param(
        [string]$WorktreeName
    )

    if (-not $WorktreeName) {
        $choices = Get-GitWorktrees
        if (-not $choices) {
            Write-Error "No git worktrees found."
            return $null
        }

        $selection = $choices | fzf --prompt "Select worktree> "
        if ([string]::IsNullOrWhiteSpace($selection)) {
            Write-Host "No worktree selected."
            return $null
        }

        return $selection.Trim()
    }

    return $WorktreeName
}

function Set-GitWorktree {
    param(
        [Parameter()]
        [string]$WorktreeName
    )

    $WorktreeName = Select-GitWorktreeName -WorktreeName $WorktreeName
    if ($null -eq $WorktreeName) {
        return
    }

    $matchingWorktree = Get-GitWorktreePathByName -WorktreeName $WorktreeName

    if ($null -eq $matchingWorktree) {
        Write-Error "Worktree '$WorktreeName' not found."
        return
    }

    Set-Location $matchingWorktree
}

function New-GitWorktree {
    param(
        [Parameter(Mandatory)]
        [string]$WorktreeName
    )
    $Path = "$env:USERPROFILE\Source\worktrees\$WorktreeName"

    git worktree add $Path -b $WorktreeName

    Set-Location $Path
}

function Remove-GitWorktree {
    param(
        [Parameter()]
        [string]$WorktreeName
    )

    $WorktreeName = Select-GitWorktreeName -WorktreeName $WorktreeName
    if ($null -eq $WorktreeName) {
        return
    }

    $matchingWorktree = Get-GitWorktreePathByName -WorktreeName $WorktreeName

    if ($null -eq $matchingWorktree) {
        Write-Error "Worktree '$WorktreeName' not found."
        return
    }

    git worktree remove $matchingWorktree

    # Check if a branch with the same name exists
    $branchExists = git rev-parse --verify --quiet "refs/heads/$WorktreeName"
    if ($branchExists) {
        git branch -d $WorktreeName
    }
}

function Get-GitParentBranch {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Branch
    )
    # Get current branch if not specified
    if (-not $Branch) {
        $Branch = git branch --show-current 2>$null
        if ([string]::IsNullOrWhiteSpace($Branch)) {
            Write-Error "Not currently on a branch (detached HEAD?)."
            return
        }
    }

    Write-Verbose "Finding parent branch for '$Branch'"

    # Get recent commits from the current branch (last 100 commits should be enough)
    $commits = git log --format=%H -n 100 $Branch 2>$null

    if (-not $commits) {
        Write-Error "Unable to get commit history for branch '$Branch'."
        return
    }

    foreach ($commit in $commits) {
        # Find all origin branches that point at this commit
        $remoteBranchesAtCommit = git for-each-ref --format='%(refname:short)' refs/remotes/origin --points-at $commit 2>$null |
        Where-Object { $_ -ne "origin/$Branch" }

        $branchesAtCommit = $remoteBranchesAtCommit | ForEach-Object {
            if ($_.StartsWith('origin/')) {
                return $_.Substring(7)
            }

            return $_
        }

        if ($branchesAtCommit) {
            Write-Verbose "Found branches at commit ${commit}: $($branchesAtCommit -join ', ')"

            # Prioritize branches for ordering: development branches > feature branches > master/main > others
            $developmentBranches = @($branchesAtCommit | Where-Object { $_ -match '^[A-Z]+-\d+' })
            $featureBranches = @($branchesAtCommit | Where-Object { $_ -match '^feature/[A-Z]+-\d+' })
            $mainBranches = @($branchesAtCommit | Where-Object { $_ -match '^(master|main)$' })
            $otherBranches = @($branchesAtCommit | Where-Object {
                    ($_ -notmatch '^[A-Z]+-\d+') -and
                    ($_ -notmatch '^feature/[A-Z]+-\d+') -and
                    ($_ -notmatch '^(master|main)$')
                })

            $candidateBranches = @(
                $developmentBranches
                $featureBranches
                $mainBranches
                $otherBranches
            ) | Select-Object -Unique

            if ($candidateBranches.Count -eq 1) {
                Write-Verbose "Selecting only available branch: $($candidateBranches)"
                return $candidateBranches
            }

            if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) {
                Write-Warning "fzf is not available. Selecting first candidate: $($candidateBranches[0])"
                return $candidateBranches[0]
            }

            $helpText = "Multiple parent branch candidates found for '$Branch'. Choose one."
            $selectedBranch = $candidateBranches | fzf --prompt "Parent branch> " --header "$helpText"

            if ([string]::IsNullOrWhiteSpace($selectedBranch)) {
                Write-Error "No parent branch selected."
                return
            }

            return $selectedBranch.Trim()
        }
    }

    # If we didn't find any parent branch, fall back to master or main
    $masterExists = git rev-parse --verify --quiet "refs/remotes/origin/master" 2>$null
    if ($masterExists) {
        Write-Verbose "No parent found, falling back to 'master'"
        return 'master'
    }

    $mainExists = git rev-parse --verify --quiet "refs/remotes/origin/main" 2>$null
    if ($mainExists) {
        Write-Verbose "No parent found, falling back to 'main'"
        return 'main'
    }

    Write-Error "Unable to determine parent branch for '$Branch'."
}

function New-DraftGitHubPullRequest {
    git push 2>$null

    $currentBranch = git branch --show-current
    $issueKeyMatch = [regex]::Match($currentBranch, '[A-Z]+-\d+')
    if (-not $issueKeyMatch.Success) {
        Write-Error "No Jira issue key found in current branch name '$currentBranch'."
        return
    }

    $issueKey = $issueKeyMatch.Value
    $title = Get-JiraIssueTitle -IssueKey $issueKey

    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        Write-Error "GitHub CLI (gh) is not installed or not on PATH."
        return
    }

    $baseBranch = Get-GitParentBranch

    $prTitle = "${issueKey}: $title"

    $reviewers = @("LanceBresslerPar", "francis-jacobs-partech", "vinay-panjabi", "`"@copilot`"")
    $reviewerArgs = $reviewers | ForEach-Object { "--reviewer", $_ }

    gh pr create --draft --title "$prTitle" --fill-verbose --base "$baseBranch" --head "$currentBranch" --assignee "@me" @reviewerArgs
}

Set-Alias -Name gitco -Value GitCheckoutFuzzy
Set-Alias -Name gitpr -Value New-DraftGitHubPullRequest
Set-Alias -Name jco -Value New-JiraBranch
Set-Alias -Name gwt -Value New-GitWorktree
Set-Alias -Name swt -Value Set-GitWorktree
Set-Alias -Name rwt -Value Remove-GitWorktree

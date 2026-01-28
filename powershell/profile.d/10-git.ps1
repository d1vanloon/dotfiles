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

Set-Alias -Name gitco -Value GitCheckoutFuzzy

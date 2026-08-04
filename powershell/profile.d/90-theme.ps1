# Theming

$powerShellRoot = Split-Path -Parent $PSScriptRoot
$ohMyPoshThemePath = Join-Path $powerShellRoot 'theme.omp.json'

oh-my-posh init pwsh --config "$ohMyPoshThemePath" | Invoke-Expression

function Set-PoshGitStatus {
    $global:GitStatus = Get-GitStatus
    $env:POSH_GIT_STRING = Write-GitStatus -Status $global:GitStatus

    if ($global:GitStatus -and $global:GitStatus.RepoName) {
        $Host.UI.RawUI.WindowTitle = $global:GitStatus.RepoName
    }
}

New-Alias -Name 'Set-PoshContext' -Value 'Set-PoshGitStatus' -Scope Global -Force

# Setup:
# > Install-Module PANSIES -AllowClobber
# > Install-Module PowerLine
# > Install-Module posh-git
# > winget install JanDeDobbeleer.OhMyPosh -s winget
# > Install-Module Get-ChildItemColor
# > Install-Module z -AllowClobber
# > Install-Module -Name PSFzf

$profileParts = @(
    'profile.d/00-modules.ps1',
    'profile.d/10-git.ps1',
    'profile.d/20-filesystem.ps1',
    'profile.d/30-security-gpg.ps1',
    'profile.d/40-env.ps1',
    'profile.d/50-utils.ps1',
    'profile.d/60-homelab.ps1',
    'profile.d/70-media.ps1',
    'profile.d/90-theme.ps1',
    'profile.d/99-commandnotfound.ps1'
)

foreach ($part in $profileParts) {
    $path = Join-Path -Path $PSScriptRoot -ChildPath $part
    if (Test-Path -Path $path) {
        . $path
    }
    else {
        Write-Warning "Profile part not found: $path"
    }
}

# Helpful Aliases
Set-Alias which Get-Command
Set-Alias l Get-ChildItemColor -Option AllScope
Set-Alias ls Get-ChildItemColorFormatWide -Option AllScope
Set-Alias -Name youtube-dl -Value yt-dlp
Set-Alias -Name ytdl -Value yt-dlp
Set-Alias -Name code -Value code-insiders

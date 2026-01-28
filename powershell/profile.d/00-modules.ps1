# CLI niceness
Import-Module PSReadLine

# Improves directory listings
Import-Module Get-ChildItemColor

# Git prompt enhancements
Import-Module posh-git
$GitPromptSettings.BranchNameLimit = 20

# Quicker directory switching
Import-Module z

# Fuzzy searching
Import-Module PSFzf
# replace 'Ctrl+t' and 'Ctrl+r' with your preferred bindings:
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
Set-PSReadLineKeyHandler -Key Tab -ScriptBlock { Invoke-FzfTabCompletion }

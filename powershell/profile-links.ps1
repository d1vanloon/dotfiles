<#
.SYNOPSIS
Links the repo's PowerShell profile assets into the current user's PowerShell profile directory.

.DESCRIPTION
Creates links for the profile entrypoint, profile fragments directory, and Oh My Posh
theme so that PowerShell loads the versions from this repository. If symbolic links
cannot be created, directories fall back to junctions or copies and files fall back to
copies.

.PARAMETER Force
Replace existing items at the destination.

.EXAMPLE
./profile-links.ps1

.EXAMPLE
./profile-links.ps1 -Force
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
	[switch]$Force
)

$ErrorActionPreference = 'Stop'

$helperScriptPath = Join-Path (Join-Path (Split-Path -Parent $PSScriptRoot) 'helpers') 'links.ps1'
if (-not (Test-Path -LiteralPath $helperScriptPath -PathType Leaf)) {
	throw "Expected helper script not found: $helperScriptPath"
}

. $helperScriptPath

function Get-PwshProfilePath {
	if (-not $PROFILE -or -not $PROFILE.CurrentUserAllHosts) {
		throw 'Unable to resolve $PROFILE.CurrentUserAllHosts for this host.'
	}

	return $PROFILE.CurrentUserAllHosts
}

$sourceProfile = Join-Path $PSScriptRoot 'profile.ps1'
$sourceProfileD = Join-Path $PSScriptRoot 'profile.d'
$sourceTheme = Join-Path $PSScriptRoot 'theme.omp.json'

foreach ($path in @($sourceProfile, $sourceProfileD, $sourceTheme)) {
	if (-not (Test-Path -LiteralPath $path)) {
		throw "Missing expected PowerShell source path: $path"
	}
}

$profilePath = Get-PwshProfilePath
$profileDir = Split-Path -Parent $profilePath
Ensure-Directory -Path $profileDir

New-Link -LinkPath $profilePath -TargetPath $sourceProfile -Type File -Force:$Force
New-Link -LinkPath (Join-Path $profileDir 'profile.d') -TargetPath $sourceProfileD -Type Directory -Force:$Force
New-Link -LinkPath (Join-Path $profileDir 'theme.omp.json') -TargetPath $sourceTheme -Type File -Force:$Force

Write-Host "Installed pwsh profile links into: $profileDir" -ForegroundColor Green

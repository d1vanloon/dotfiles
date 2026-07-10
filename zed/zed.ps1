<#
.SYNOPSIS
Links the repo's Zed settings into the current user's Roaming AppData folder.

.DESCRIPTION
Links zed/settings.json from this repository to %APPDATA%\Zed\settings.json.
If a symbolic link cannot be created, the file is copied instead.

.PARAMETER Force
Replace an existing destination settings file when it does not already point to
the repo settings file.

.EXAMPLE
./zed.ps1

.EXAMPLE
./zed.ps1 -Force
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
	[switch]$Force
)

$ErrorActionPreference = 'Stop'

$helperScriptPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'helpers/links.ps1'
if (-not (Test-Path -LiteralPath $helperScriptPath -PathType Leaf)) {
	throw "Expected helper script not found: $helperScriptPath"
}

. $helperScriptPath

function Get-RoamingAppDataPath {
	$candidates = @(
		[System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::ApplicationData),
		$env:APPDATA
	) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

	foreach ($path in $candidates) {
		if (Test-Path -LiteralPath $path -PathType Container) {
			return $path
		}
	}

	throw 'Unable to resolve the current user Roaming AppData directory.'
}

$sourceSettingsPath = Join-Path $PSScriptRoot 'settings.json'
if (-not (Test-Path -LiteralPath $sourceSettingsPath -PathType Leaf)) {
	throw "Expected file not found: $sourceSettingsPath"
}

$destSettingsPath = Join-Path (Join-Path (Get-RoamingAppDataPath) 'Zed') 'settings.json'

New-Link -LinkPath $destSettingsPath -TargetPath $sourceSettingsPath -Type File -Force:$Force
Write-Host "Installed Zed settings link: $destSettingsPath -> $sourceSettingsPath" -ForegroundColor Green
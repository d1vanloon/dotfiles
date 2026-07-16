<#
.SYNOPSIS
Links the repo's AWS config into the current user's ~/.aws directory.

.DESCRIPTION
Links aws/config from this repository to ~/.aws/config.
If a symbolic link cannot be created, the file is copied instead.

.PARAMETER Force
Replace an existing destination config file when it does not already point to
the repo config file.

.EXAMPLE
./aws.ps1

.EXAMPLE
./aws.ps1 -Force
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

function Get-UserHomePath {
	$candidates = @(
		[System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::UserProfile),
		$env:USERPROFILE,
		$HOME
	) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

	foreach ($path in $candidates) {
		if (Test-Path -LiteralPath $path -PathType Container) {
			return $path
		}
	}

	throw 'Unable to resolve the current user home directory.'
}

$sourceConfigPath = Join-Path $PSScriptRoot 'config'
if (-not (Test-Path -LiteralPath $sourceConfigPath -PathType Leaf)) {
	throw "Expected file not found: $sourceConfigPath"
}

$destConfigPath = Join-Path (Join-Path (Get-UserHomePath) '.aws') 'config'

New-Link -LinkPath $destConfigPath -TargetPath $sourceConfigPath -Type File -Force:$Force
Write-Host "Installed AWS config link: $destConfigPath -> $sourceConfigPath" -ForegroundColor Green

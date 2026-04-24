<#
.SYNOPSIS
Links the repo's profile-specific Git config into the current user's home directory.

.DESCRIPTION
Selects the profile-specific .gitconfig file from this directory and links it to
~/.gitconfig. If symbolic links cannot be created, the file is copied instead.

.PARAMETER InstallProfile
The profile to install. Valid values are 'Personal' (default) and 'Work'.

.PARAMETER Force
Replace an existing ~/.gitconfig when it does not already point to the selected
repo config.

.EXAMPLE
./git.ps1

.EXAMPLE
./git.ps1 -InstallProfile Work
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
	[ValidateSet('Personal', 'Work')]
	[string]$InstallProfile = 'Personal',
	[switch]$Force
)

$ErrorActionPreference = 'Stop'

$helperScriptPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'helpers/links.ps1'
if (-not (Test-Path -LiteralPath $helperScriptPath -PathType Leaf)) {
	throw "Expected helper script not found: $helperScriptPath"
}

. $helperScriptPath

function Get-RepoGitConfigPath {
	param([Parameter(Mandatory)] [string]$ProfileName)

	$gitConfigPath = Join-Path (Join-Path $PSScriptRoot ($ProfileName.ToLower())) '.gitconfig'
	if (-not (Test-Path -LiteralPath $gitConfigPath -PathType Leaf)) {
		throw "Expected file not found: $gitConfigPath"
	}

	return $gitConfigPath
}

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

$sourceGitConfigPath = Get-RepoGitConfigPath -ProfileName $InstallProfile
$destPath = Join-Path (Get-UserHomePath) '.gitconfig'

New-Link -LinkPath $destPath -TargetPath $sourceGitConfigPath -Type File -Force:$Force
Write-Host "Installed .gitconfig link: $destPath -> $sourceGitConfigPath" -ForegroundColor Green

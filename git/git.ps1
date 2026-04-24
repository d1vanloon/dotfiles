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

function Get-RepoGitConfigPath {
	param([Parameter(Mandatory)] [string]$ProfileName)

	$gitConfigPath = Join-Path $PSScriptRoot ($ProfileName.ToLower()) '.gitconfig'
	if (-not (Test-Path -LiteralPath $gitConfigPath -PathType Leaf)) {
		throw "Expected file not found: $gitConfigPath"
	}

	return $gitConfigPath
}

function Test-LinkMatchesTarget {
	param(
		[Parameter(Mandatory)] [string]$LinkPath,
		[Parameter(Mandatory)] [string]$TargetPath
	)

	try {
		$item = Get-Item -LiteralPath $LinkPath -Force -ErrorAction Stop
	}
	catch {
		return $false
	}

	$targets = $null
	try { $targets = $item.Target } catch { $targets = $null }
	if (-not $targets) {
		return $false
	}

	$resolvedTarget = $null
	try { $resolvedTarget = (Resolve-Path -LiteralPath $TargetPath -ErrorAction Stop).Path } catch { $resolvedTarget = $null }

	foreach ($t in @($targets)) {
		if (-not $t) { continue }
		try {
			$resolvedT = (Resolve-Path -LiteralPath $t -ErrorAction Stop).Path
			if ($resolvedTarget -and ($resolvedT -eq $resolvedTarget)) {
				return $true
			}
		}
		catch {
			if ($t -eq $TargetPath) {
				return $true
			}
		}
	}

	return $false
}

function Backup-OrRemoveExisting {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param(
		[Parameter(Mandatory)] [string]$Path,
		[string]$TargetPath,
		[switch]$Force
	)

	if (-not (Test-Path -LiteralPath $Path)) {
		return
	}

	if ($TargetPath -and (Test-LinkMatchesTarget -LinkPath $Path -TargetPath $TargetPath)) {
		return
	}

	if (-not $Force) {
		if ($WhatIfPreference) {
			Write-Warning "Destination already exists and would be replaced: $Path (re-run with -Force to replace)"
			return
		}

		throw "Destination already exists: $Path (use -Force to replace)"
	}

	if ($PSCmdlet.ShouldProcess($Path, 'Remove')) {
		Remove-Item -LiteralPath $Path -Recurse -Force
	}
}

function New-Link {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param(
		[Parameter(Mandatory)] [string]$LinkPath,
		[Parameter(Mandatory)] [string]$TargetPath,
		[Parameter(Mandatory)] [ValidateSet('File', 'Directory')] [string]$Type,
		[switch]$Force
	)

	Backup-OrRemoveExisting -Path $LinkPath -TargetPath $TargetPath -Force:$Force

	if ((Test-Path -LiteralPath $LinkPath) -and (Test-LinkMatchesTarget -LinkPath $LinkPath -TargetPath $TargetPath)) {
		return
	}

	if ($PSCmdlet.ShouldProcess($LinkPath, "Link -> $TargetPath")) {
		try {
			New-Item -Path $LinkPath -ItemType SymbolicLink -Target $TargetPath -Force | Out-Null
			return
		}
		catch {
			Write-Warning "Unable to create symlink for file; copying instead: $LinkPath"
			Copy-Item -LiteralPath $TargetPath -Destination $LinkPath -Force
		}
	}
}

$sourceGitConfigPath = Get-RepoGitConfigPath -ProfileName $InstallProfile
$destPath = Join-Path $env:USERPROFILE '.gitconfig'

New-Link -LinkPath $destPath -TargetPath $sourceGitConfigPath -Type File -Force:$Force
Write-Host "Installed .gitconfig link: $destPath -> $sourceGitConfigPath" -ForegroundColor Green

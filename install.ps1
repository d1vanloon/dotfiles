<#
.SYNOPSIS
Installs this repo's PowerShell profile by linking files into the host profile location.

.DESCRIPTION
Creates links in the directory that contains $PROFILE so that PowerShell loads the repo's
profile parts (profile.d) and Oh My Posh theme.

Default behavior installs for the current host profile path ($PROFILE).

If symbolic links cannot be created (no admin + no Developer Mode), directories fall back
to junctions and files fall back to copies (with a warning).

.PARAMETER Force
Replace existing items at the destination.

.EXAMPLE
./install.ps1

.EXAMPLE
./install.ps1 -Force
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
	[switch]$Force
)

$ErrorActionPreference = 'Stop'

function Get-RepoPowerShellRoot {
	$psRoot = Join-Path $PSScriptRoot 'powershell'
	if (-not (Test-Path -Path $psRoot -PathType Container)) {
		throw "Expected folder not found: $psRoot"
	}
	return $psRoot
}

function Get-PwshProfilePath {
	if (-not $PROFILE -or -not $PROFILE.CurrentUserAllHosts) {
		throw 'Unable to resolve $PROFILE.CurrentUserAllHosts for this host.'
	}

	return $PROFILE.CurrentUserAllHosts
}

function Ensure-Directory {
	param([Parameter(Mandatory)] [string]$Path)

	if (-not (Test-Path -Path $Path -PathType Container)) {
		New-Item -Path $Path -ItemType Directory -Force | Out-Null
	}
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

	$parent = Split-Path -Parent $LinkPath
	Ensure-Directory -Path $parent

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
			if ($Type -eq 'Directory') {
				if ($IsWindows) {
					try {
						New-Item -Path $LinkPath -ItemType Junction -Target $TargetPath -Force | Out-Null
						Write-Warning "Created junction instead of symlink: $LinkPath"
						return
					}
					catch {
						throw
					}
				}

				Write-Warning "Unable to create symlink for directory; copying instead: $LinkPath"
				Copy-Item -LiteralPath $TargetPath -Destination $LinkPath -Recurse -Force
				return
			}

			Write-Warning "Unable to create symlink for file; copying instead: $LinkPath"
			Copy-Item -LiteralPath $TargetPath -Destination $LinkPath -Force
		}
	}
}

$psRoot = Get-RepoPowerShellRoot
$sourceProfile = Join-Path $psRoot 'profile.ps1'
$sourceProfileD = Join-Path $psRoot 'profile.d'
$sourceTheme = Join-Path $psRoot 'theme.omp.json'

foreach ($p in @($sourceProfile, $sourceProfileD, $sourceTheme)) {
	if (-not (Test-Path -LiteralPath $p)) {
		throw "Missing expected source path: $p"
	}
}

$profilePath = Get-PwshProfilePath
$profileDir = Split-Path -Parent $profilePath
Ensure-Directory -Path $profileDir

New-Link -LinkPath $profilePath -TargetPath $sourceProfile -Type File -Force:$Force
New-Link -LinkPath (Join-Path $profileDir 'profile.d') -TargetPath $sourceProfileD -Type Directory -Force:$Force
New-Link -LinkPath (Join-Path $profileDir 'theme.omp.json') -TargetPath $sourceTheme -Type File -Force:$Force

Write-Host "Installed pwsh profile links into: $profileDir" -ForegroundColor Green

Write-Host 'Done.' -ForegroundColor Green

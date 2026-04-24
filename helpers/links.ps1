function Ensure-Directory {
	param([Parameter(Mandatory)] [string]$Path)

	if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
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

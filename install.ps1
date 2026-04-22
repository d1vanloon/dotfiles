<#
.SYNOPSIS
Installs this repo's PowerShell profile and fonts.

.DESCRIPTION
Creates links in the directory that contains $PROFILE so that PowerShell loads the repo's
profile parts (profile.d) and Oh My Posh theme. Also installs fonts from the fonts/
directory into the current user's font directory.

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

function Get-RepoFontsRoot {
	$fontsRoot = Join-Path $PSScriptRoot 'fonts'
	if (-not (Test-Path -Path $fontsRoot -PathType Container)) {
		throw "Expected folder not found: $fontsRoot"
	}
	return $fontsRoot
}

function Get-RepoTerminalSettingsPath {
	$settingsPath = Join-Path $PSScriptRoot 'terminal' 'setttings.json'
	if (-not (Test-Path -Path $settingsPath -PathType Leaf)) {
		throw "Expected file not found: $settingsPath"
	}
	return $settingsPath
}

function Merge-JsonObject {
	param(
		[Parameter(Mandatory)] [PSCustomObject]$Base,
		[Parameter(Mandatory)] [PSCustomObject]$Override
	)

	$result = $Base | ConvertTo-Json -Depth 100 | ConvertFrom-Json

	foreach ($prop in $Override.PSObject.Properties) {
		$existing = $result.PSObject.Properties[$prop.Name]
		if ($existing -and ($prop.Value -is [PSCustomObject]) -and ($existing.Value -is [PSCustomObject])) {
			$result.PSObject.Properties.Remove($prop.Name)
			$result | Add-Member -NotePropertyName $prop.Name -NotePropertyValue (Merge-JsonObject -Base $existing.Value -Override $prop.Value)
		}
		else {
			if ($existing) {
				$result.PSObject.Properties.Remove($prop.Name)
			}
			$result | Add-Member -NotePropertyName $prop.Name -NotePropertyValue $prop.Value
		}
	}

	return $result
}

function Install-TerminalSettings {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param([Parameter(Mandatory)] [string]$SourceSettingsPath)

	$terminalSettingsPath = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'

	if (-not (Test-Path -LiteralPath $terminalSettingsPath)) {
		Write-Warning "Windows Terminal settings not found at: $terminalSettingsPath"
		return
	}

	$sourceSettings = Get-Content -LiteralPath $SourceSettingsPath -Raw | ConvertFrom-Json
	$currentSettings = Get-Content -LiteralPath $terminalSettingsPath -Raw | ConvertFrom-Json

	$merged = Merge-JsonObject -Base $currentSettings -Override $sourceSettings

	if ($PSCmdlet.ShouldProcess($terminalSettingsPath, 'Merge terminal settings')) {
		$merged | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $terminalSettingsPath -Encoding UTF8
		Write-Host "Merged terminal settings into: $terminalSettingsPath" -ForegroundColor Green
	}
}

function Install-Fonts {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param([Parameter(Mandatory)] [string]$FontsSourceDir)

	$userFontsDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
	Ensure-Directory -Path $userFontsDir

	$fontFiles = Get-ChildItem -Path $FontsSourceDir -File | Where-Object { $_.Extension -in '.ttf', '.otf' }

	if (-not $fontFiles) {
		Write-Warning "No font files found in: $FontsSourceDir"
		return
	}

	$regPath = 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'

	foreach ($font in $fontFiles) {
		$destPath = Join-Path $userFontsDir $font.Name
		$fontRegName = [System.IO.Path]::GetFileNameWithoutExtension($font.Name) + ' (TrueType)'

		$fileExists = Test-Path -LiteralPath $destPath
		$regExists = $null -ne (Get-ItemProperty -Path $regPath -Name $fontRegName -ErrorAction SilentlyContinue)

		if ($fileExists -and $regExists) {
			Write-Verbose "Font already installed, skipping: $($font.Name)"
			continue
		}

		if ($PSCmdlet.ShouldProcess($font.Name, "Install font to $userFontsDir")) {
			Copy-Item -LiteralPath $font.FullName -Destination $destPath -Force
			Set-ItemProperty -Path $regPath -Name $fontRegName -Value $destPath -Force
			Write-Host "Installed font: $($font.Name)" -ForegroundColor Green
		}
	}
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
$fontsRoot = Get-RepoFontsRoot
$terminalSettings = Get-RepoTerminalSettingsPath

foreach ($p in @($sourceProfile, $sourceProfileD, $sourceTheme, $fontsRoot, $terminalSettings)) {
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

Install-Fonts -FontsSourceDir $fontsRoot
Install-TerminalSettings -SourceSettingsPath $terminalSettings

Write-Host 'Done.' -ForegroundColor Green

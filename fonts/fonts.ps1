<#
.SYNOPSIS
Installs fonts from this directory into the current user's font directory.

.DESCRIPTION
Copies .ttf and .otf font files from the same directory as this script to
the current user's fonts directory (%LOCALAPPDATA%\Microsoft\Windows\Fonts)
and registers each font in the current user's registry.

.EXAMPLE
./fonts.ps1
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param()

$ErrorActionPreference = 'Stop'

function Ensure-Directory {
	param([Parameter(Mandatory)] [string]$Path)

	if (-not (Test-Path -Path $Path -PathType Container)) {
		New-Item -Path $Path -ItemType Directory -Force | Out-Null
	}
}

$userFontsDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
Ensure-Directory -Path $userFontsDir

$fontFiles = Get-ChildItem -Path $PSScriptRoot -File | Where-Object { $_.Extension -in '.ttf', '.otf' }

if (-not $fontFiles) {
	Write-Warning "No font files found in: $PSScriptRoot"
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

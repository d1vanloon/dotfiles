<#
.SYNOPSIS
Merges the repo's terminal settings into the Windows Terminal settings file.

.DESCRIPTION
Reads setttings.json from this directory and deep-merges it into the current
Windows Terminal settings, with values from this repo taking precedence over
existing settings.

.EXAMPLE
./terminal.ps1
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param()

$ErrorActionPreference = 'Stop'

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

$sourceSettingsPath = Join-Path $PSScriptRoot 'setttings.json'

if (-not (Test-Path -LiteralPath $sourceSettingsPath -PathType Leaf)) {
	throw "Expected settings file not found: $sourceSettingsPath"
}

$terminalSettingsPath = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'

if (-not (Test-Path -LiteralPath $terminalSettingsPath)) {
	Write-Warning "Windows Terminal settings not found at: $terminalSettingsPath"
	return
}

$sourceSettings = Get-Content -LiteralPath $sourceSettingsPath -Raw | ConvertFrom-Json
$currentSettings = Get-Content -LiteralPath $terminalSettingsPath -Raw | ConvertFrom-Json

$merged = Merge-JsonObject -Base $currentSettings -Override $sourceSettings

if ($PSCmdlet.ShouldProcess($terminalSettingsPath, 'Merge terminal settings')) {
	$merged | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $terminalSettingsPath -Encoding UTF8
	Write-Host "Merged terminal settings into: $terminalSettingsPath" -ForegroundColor Green
}

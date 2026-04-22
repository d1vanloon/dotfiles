<#
.SYNOPSIS
Installs Visual Studio Professional Insiders using WinGet with the repo's .vsconfig.

.DESCRIPTION
Runs winget install for Microsoft.VisualStudio.Professional.Insiders, passing the .vsconfig
file in the same directory as this script to configure installed workloads and components.

.EXAMPLE
./visual-studio.ps1
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param()

$ErrorActionPreference = 'Stop'

$vsConfigPath = Join-Path $PSScriptRoot '.vsconfig'

if (-not (Test-Path -LiteralPath $vsConfigPath -PathType Leaf)) {
	throw "Expected .vsconfig not found: $vsConfigPath"
}

if ($PSCmdlet.ShouldProcess('Microsoft.VisualStudio.Professional.Insiders', 'winget install')) {
	Write-Host 'Installing Microsoft.VisualStudio.Professional.Insiders...' -ForegroundColor Cyan
	winget install --id Microsoft.VisualStudio.Professional.Insiders --silent --accept-package-agreements --accept-source-agreements --override "--wait --quiet --config `"$vsConfigPath`""
	if ($LASTEXITCODE -ne 0) {
		Write-Warning "winget exited with code $LASTEXITCODE for Microsoft.VisualStudio.Professional.Insiders"
	}
	else {
		Write-Host 'Visual Studio Professional Insiders installed.' -ForegroundColor Green
	}
}

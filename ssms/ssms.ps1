<#
.SYNOPSIS
Installs SQL Server Management Studio using WinGet with the repo's .vsconfig.

.DESCRIPTION
Runs winget install for Microsoft.SQLServerManagementStudio.22, passing the .vsconfig
file in the same directory as this script to configure installed workloads and components.

.EXAMPLE
./ssms.ps1
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param()

$ErrorActionPreference = 'Stop'

$vsConfigPath = Join-Path $PSScriptRoot '.vsconfig'

if (-not (Test-Path -LiteralPath $vsConfigPath -PathType Leaf)) {
	throw "Expected .vsconfig not found: $vsConfigPath"
}

if ($PSCmdlet.ShouldProcess('Microsoft.SQLServerManagementStudio.22', 'winget install')) {
	Write-Host 'Installing Microsoft.SQLServerManagementStudio.22...' -ForegroundColor Cyan
	winget install --id Microsoft.SQLServerManagementStudio.22 --silent --accept-package-agreements --accept-source-agreements --override "--wait --quiet --config `"$vsConfigPath`""
	if ($LASTEXITCODE -ne 0) {
		Write-Warning "winget exited with code $LASTEXITCODE for Microsoft.SQLServerManagementStudio.22"
	}
	else {
		Write-Host 'SQL Server Management Studio installed.' -ForegroundColor Green
	}
}

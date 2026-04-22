<#
.SYNOPSIS
Installs .NET global tools listed in tools.txt.

.DESCRIPTION
Reads tool IDs from tools.txt in the same directory and installs each using
'dotnet tool install --global'. Lines may include inline comments after a #
character, which are stripped. Empty and comment-only lines are ignored.

Already-installed tools are updated instead of re-installed.

.EXAMPLE
./dotnet.ps1
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param()

$ErrorActionPreference = 'Stop'

function Get-ToolIds {
	param([Parameter(Mandatory)] [string]$Path)

	if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
		return @()
	}

	Get-Content -LiteralPath $Path |
		ForEach-Object { ($_ -split '#')[0].Trim() } |
		Where-Object { $_ -ne '' }
}

$toolsPath = Join-Path $PSScriptRoot 'tools.txt'
$toolIds = @(Get-ToolIds -Path $toolsPath)

if (-not $toolIds) {
	Write-Warning 'No .NET tools found to install.'
	return
}

foreach ($id in $toolIds) {
	if ($PSCmdlet.ShouldProcess($id, 'dotnet tool install --global')) {
		Write-Host "Installing .NET tool: $id" -ForegroundColor Cyan
		dotnet tool install --global $id 2>&1 | Tee-Object -Variable output | Out-Null
		if ($LASTEXITCODE -ne 0) {
			# Exit code 1 with "already installed" means we should update instead
			if ($output -match 'already installed') {
				Write-Verbose "Tool already installed, updating: $id"
				dotnet tool update --global $id
				if ($LASTEXITCODE -ne 0) {
					Write-Warning "dotnet tool update exited with code $LASTEXITCODE for tool: $id"
				}
			}
			else {
				Write-Warning "dotnet tool install exited with code $LASTEXITCODE for tool: $id"
			}
		}
	}
}

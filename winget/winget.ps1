<#
.SYNOPSIS
Installs winget packages based on the installation profile.

.DESCRIPTION
Reads package IDs from the common packages.txt and the profile-specific packages.txt,
then installs each package using winget.

Lines in packages.txt may include inline comments after a # character, which are stripped.
Empty and comment-only lines are ignored.

.PARAMETER InstallProfile
The profile to install. Valid values are 'Personal' (default) and 'Work'.

.EXAMPLE
./winget.ps1

.EXAMPLE
./winget.ps1 -InstallProfile Work
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
	[ValidateSet('Personal', 'Work')]
	[string]$InstallProfile = 'Personal'
)

$ErrorActionPreference = 'Stop'

function Get-PackageIds {
	param([Parameter(Mandatory)] [string]$Path)

	if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
		return @()
	}

	Get-Content -LiteralPath $Path |
		ForEach-Object { ($_ -split '#')[0].Trim() } |
		Where-Object { $_ -ne '' }
}

$commonPackagesPath = Join-Path $PSScriptRoot 'packages.txt'
$profilePackagesPath = Join-Path $PSScriptRoot $InstallProfile.ToLower() 'packages.txt'

$packageIds = @(Get-PackageIds -Path $commonPackagesPath) + @(Get-PackageIds -Path $profilePackagesPath)

if (-not $packageIds) {
	Write-Warning 'No packages found to install.'
	return
}

foreach ($id in $packageIds) {
	if ($PSCmdlet.ShouldProcess($id, 'winget install')) {
		Write-Host "Installing: $id" -ForegroundColor Cyan
		winget install --id $id --silent --accept-package-agreements --accept-source-agreements
		if ($LASTEXITCODE -ne 0) {
			Write-Warning "winget exited with code $LASTEXITCODE for package: $id"
		}
	}
}

Write-Host "Winget packages installed for profile: $InstallProfile" -ForegroundColor Green

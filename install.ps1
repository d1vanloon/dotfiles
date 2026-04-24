<#
.SYNOPSIS
Installs this repo's PowerShell profile and fonts.

.DESCRIPTION
Installs this repo's category-specific setup by delegating to the scripts under each
top-level folder. This includes linking the PowerShell profile assets, installing
PowerShell modules, merging terminal settings, linking the selected Git config, and
applying the other category installers.

Default behavior installs for the current host profile path ($PROFILE).

If symbolic links cannot be created (no admin + no Developer Mode), directories fall back
to junctions and files fall back to copies (with a warning).

.PARAMETER Force
Replace existing items at the destination.

.PARAMETER InstallProfile
The profile to install. Valid values are 'Personal' (default) and 'Work'.
Determines which git config is symlinked to ~/.gitconfig.

.EXAMPLE
./install.ps1

.EXAMPLE
./install.ps1 -InstallProfile Work

.EXAMPLE
./install.ps1 -Force
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
	[switch]$Force,
	[ValidateSet('Personal', 'Work')]
	[string]$InstallProfile = 'Personal'
)

$ErrorActionPreference = 'Stop'

function Get-RepoFontsScriptPath {
	$scriptPath = Join-Path $PSScriptRoot 'fonts' 'fonts.ps1'
	if (-not (Test-Path -Path $scriptPath -PathType Leaf)) {
		throw "Expected file not found: $scriptPath"
	}
	return $scriptPath
}

function Get-RepoGitScriptPath {
	$scriptPath = Join-Path $PSScriptRoot 'git' 'git.ps1'
	if (-not (Test-Path -Path $scriptPath -PathType Leaf)) {
		throw "Expected file not found: $scriptPath"
	}
	return $scriptPath
}

function Get-RepoTerminalScriptPath {
	$scriptPath = Join-Path $PSScriptRoot 'terminal' 'terminal.ps1'
	if (-not (Test-Path -Path $scriptPath -PathType Leaf)) {
		throw "Expected file not found: $scriptPath"
	}
	return $scriptPath
}

function Install-Fonts {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param([Parameter(Mandatory)] [string]$SourceFontsScriptPath)

	& $SourceFontsScriptPath -WhatIf:$WhatIfPreference -Verbose:($VerbosePreference -ne 'SilentlyContinue')
}

function Install-Terminal {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param([Parameter(Mandatory)] [string]$SourceTerminalScriptPath)

	& $SourceTerminalScriptPath -WhatIf:$WhatIfPreference -Verbose:($VerbosePreference -ne 'SilentlyContinue')
}

function Install-PowerShellProfile {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param(
		[Parameter(Mandatory)] [string]$SourcePowerShellProfileScriptPath
	)

	& $SourcePowerShellProfileScriptPath -Force:$Force -WhatIf:$WhatIfPreference -Verbose:($VerbosePreference -ne 'SilentlyContinue')
}

function Install-GitConfig {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param(
		[Parameter(Mandatory)] [string]$SourceGitScriptPath,
		[Parameter(Mandatory)] [string]$ProfileName
	)

	& $SourceGitScriptPath -InstallProfile $ProfileName -Force:$Force -WhatIf:$WhatIfPreference -Verbose:($VerbosePreference -ne 'SilentlyContinue')
}

function Install-WingetPackages {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param(
		[Parameter(Mandatory)] [string]$SourceWingetScriptPath,
		[Parameter(Mandatory)] [string]$ProfileName
	)

	& $SourceWingetScriptPath -InstallProfile $ProfileName -WhatIf:$WhatIfPreference -Verbose:($VerbosePreference -ne 'SilentlyContinue')
}

function Get-RepoWingetScriptPath {
	$scriptPath = Join-Path $PSScriptRoot 'winget' 'winget.ps1'
	if (-not (Test-Path -Path $scriptPath -PathType Leaf)) {
		throw "Expected file not found: $scriptPath"
	}
	return $scriptPath
}

function Get-RepoEnvVarsScriptPath {
	$scriptPath = Join-Path $PSScriptRoot 'environment-vars' 'environment-vars.ps1'
	if (-not (Test-Path -Path $scriptPath -PathType Leaf)) {
		throw "Expected file not found: $scriptPath"
	}
	return $scriptPath
}

function Get-RepoPowerShellModulesScriptPath {
	$scriptPath = Join-Path $PSScriptRoot 'powershell' 'powershell.ps1'
	if (-not (Test-Path -Path $scriptPath -PathType Leaf)) {
		throw "Expected file not found: $scriptPath"
	}
	return $scriptPath
}

function Get-RepoPowerShellProfileScriptPath {
	$scriptPath = Join-Path $PSScriptRoot 'powershell' 'profile-links.ps1'
	if (-not (Test-Path -Path $scriptPath -PathType Leaf)) {
		throw "Expected file not found: $scriptPath"
	}
	return $scriptPath
}

function Get-RepoDotnetScriptPath {
	$scriptPath = Join-Path $PSScriptRoot 'dotnet' 'dotnet.ps1'
	if (-not (Test-Path -Path $scriptPath -PathType Leaf)) {
		throw "Expected file not found: $scriptPath"
	}
	return $scriptPath
}

function Get-RepoVisualStudioScriptPath {
	$scriptPath = Join-Path $PSScriptRoot 'visual-studio' 'visual-studio.ps1'
	if (-not (Test-Path -Path $scriptPath -PathType Leaf)) {
		throw "Expected file not found: $scriptPath"
	}
	return $scriptPath
}

function Get-RepoSsmsScriptPath {
	$scriptPath = Join-Path $PSScriptRoot 'ssms' 'ssms.ps1'
	if (-not (Test-Path -Path $scriptPath -PathType Leaf)) {
		throw "Expected file not found: $scriptPath"
	}
	return $scriptPath
}

function Install-EnvironmentVars {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param(
		[Parameter(Mandatory)] [string]$SourceEnvVarsScriptPath,
		[Parameter(Mandatory)] [string]$ProfileName
	)

	& $SourceEnvVarsScriptPath -InstallProfile $ProfileName -WhatIf:$WhatIfPreference -Verbose:($VerbosePreference -ne 'SilentlyContinue')
}

function Install-PowerShellModules {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param([Parameter(Mandatory)] [string]$SourcePowerShellScriptPath)

	& $SourcePowerShellScriptPath -WhatIf:$WhatIfPreference -Verbose:($VerbosePreference -ne 'SilentlyContinue')
}

function Install-DotnetTools {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param(
		[Parameter(Mandatory)] [string]$SourceDotnetScriptPath,
		[Parameter(Mandatory)] [string]$ProfileName
	)

	& $SourceDotnetScriptPath -InstallProfile $ProfileName -WhatIf:$WhatIfPreference -Verbose:($VerbosePreference -ne 'SilentlyContinue')
}

function Install-VisualStudio {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param([Parameter(Mandatory)] [string]$SourceVisualStudioScriptPath)

	& $SourceVisualStudioScriptPath -WhatIf:$WhatIfPreference -Verbose:($VerbosePreference -ne 'SilentlyContinue')
}

function Install-Ssms {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param(
		[Parameter(Mandatory)] [string]$SourceSsmsScriptPath,
		[Parameter(Mandatory)] [string]$ProfileName
	)

	& $SourceSsmsScriptPath -InstallProfile $ProfileName -WhatIf:$WhatIfPreference -Verbose:($VerbosePreference -ne 'SilentlyContinue')
}
$powerShellProfileScript = Get-RepoPowerShellProfileScriptPath
$fontsScript = Get-RepoFontsScriptPath
$terminalScript = Get-RepoTerminalScriptPath
$gitScript = Get-RepoGitScriptPath
$wingetScript = Get-RepoWingetScriptPath
$visualStudioScript = Get-RepoVisualStudioScriptPath
$ssmsScript = Get-RepoSsmsScriptPath
$dotnetScript = Get-RepoDotnetScriptPath
$envVarsScript = Get-RepoEnvVarsScriptPath
$psModulesScript = Get-RepoPowerShellModulesScriptPath

foreach ($p in @($powerShellProfileScript, $fontsScript, $terminalScript, $gitScript, $wingetScript, $visualStudioScript, $ssmsScript, $dotnetScript, $envVarsScript, $psModulesScript)) {
	if (-not (Test-Path -LiteralPath $p)) {
		throw "Missing expected source path: $p"
	}
}

Install-PowerShellProfile -SourcePowerShellProfileScriptPath $powerShellProfileScript
Install-PowerShellModules -SourcePowerShellScriptPath $psModulesScript
Install-GitConfig -SourceGitScriptPath $gitScript -ProfileName $InstallProfile
Install-Fonts -SourceFontsScriptPath $fontsScript
Install-Terminal -SourceTerminalScriptPath $terminalScript
Install-WingetPackages -SourceWingetScriptPath $wingetScript -ProfileName $InstallProfile
Install-DotnetTools -SourceDotnetScriptPath $dotnetScript -ProfileName $InstallProfile
Install-VisualStudio -SourceVisualStudioScriptPath $visualStudioScript
Install-Ssms -SourceSsmsScriptPath $ssmsScript -ProfileName $InstallProfile
Install-EnvironmentVars -SourceEnvVarsScriptPath $envVarsScript -ProfileName $InstallProfile

Write-Host 'Done.' -ForegroundColor Green

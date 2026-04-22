<#
.SYNOPSIS
Installs this repo's PowerShell profile and fonts.

.DESCRIPTION
Creates links in the directory that contains $PROFILE so that PowerShell loads the repo's
profile parts (profile.d) and Oh My Posh theme. Also installs fonts from the fonts/
directory into the current user's font directory, merges terminal settings, and symlinks
the appropriate git config based on the selected profile.

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

function Get-RepoPowerShellRoot {
	$psRoot = Join-Path $PSScriptRoot 'powershell'
	if (-not (Test-Path -Path $psRoot -PathType Container)) {
		throw "Expected folder not found: $psRoot"
	}
	return $psRoot
}

function Get-RepoFontsScriptPath {
	$scriptPath = Join-Path $PSScriptRoot 'fonts' 'fonts.ps1'
	if (-not (Test-Path -Path $scriptPath -PathType Leaf)) {
		throw "Expected file not found: $scriptPath"
	}
	return $scriptPath
}

function Get-RepoGitConfigPath {
	param([Parameter(Mandatory)] [string]$ProfileName)

	$gitConfigPath = Join-Path $PSScriptRoot 'git' $ProfileName.ToLower() '.gitconfig'
	if (-not (Test-Path -Path $gitConfigPath -PathType Leaf)) {
		throw "Expected file not found: $gitConfigPath"
	}
	return $gitConfigPath
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

function Install-GitConfig {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param([Parameter(Mandatory)] [string]$SourceGitConfigPath)

	$destPath = Join-Path $env:USERPROFILE '.gitconfig'
	New-Link -LinkPath $destPath -TargetPath $SourceGitConfigPath -Type File -Force:$Force
	Write-Host "Installed .gitconfig link: $destPath -> $SourceGitConfigPath" -ForegroundColor Green
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

function Get-RepoPowerShellScriptPath {
	$scriptPath = Join-Path $PSScriptRoot 'powershell' 'powershell.ps1'
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
	param([Parameter(Mandatory)] [string]$SourceDotnetScriptPath)

	& $SourceDotnetScriptPath -WhatIf:$WhatIfPreference -Verbose:($VerbosePreference -ne 'SilentlyContinue')
}

function Install-VisualStudio {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param([Parameter(Mandatory)] [string]$SourceVisualStudioScriptPath)

	& $SourceVisualStudioScriptPath -WhatIf:$WhatIfPreference -Verbose:($VerbosePreference -ne 'SilentlyContinue')
}

function Install-Ssms {
	[CmdletBinding(SupportsShouldProcess = $true)]
	param([Parameter(Mandatory)] [string]$SourceSsmsScriptPath)

	& $SourceSsmsScriptPath -WhatIf:$WhatIfPreference -Verbose:($VerbosePreference -ne 'SilentlyContinue')
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
$fontsScript = Get-RepoFontsScriptPath
$terminalScript = Get-RepoTerminalScriptPath
$gitConfigPath = Get-RepoGitConfigPath -ProfileName $InstallProfile
$wingetScript = Get-RepoWingetScriptPath
$visualStudioScript = Get-RepoVisualStudioScriptPath
$ssmsScript = Get-RepoSsmsScriptPath
$dotnetScript = Get-RepoDotnetScriptPath
$envVarsScript = Get-RepoEnvVarsScriptPath
$psModulesScript = Get-RepoPowerShellScriptPath

foreach ($p in @($sourceProfile, $sourceProfileD, $sourceTheme, $fontsScript, $terminalScript, $gitConfigPath, $wingetScript, $visualStudioScript, $ssmsScript, $dotnetScript, $envVarsScript, $psModulesScript)) {
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

Install-PowerShellModules -SourcePowerShellScriptPath $psModulesScript
Install-GitConfig -SourceGitConfigPath $gitConfigPath
Install-Fonts -SourceFontsScriptPath $fontsScript
Install-Terminal -SourceTerminalScriptPath $terminalScript
Install-WingetPackages -SourceWingetScriptPath $wingetScript -ProfileName $InstallProfile
Install-DotnetTools -SourceDotnetScriptPath $dotnetScript
Install-VisualStudio -SourceVisualStudioScriptPath $visualStudioScript
Install-Ssms -SourceSsmsScriptPath $ssmsScript
Install-EnvironmentVars -SourceEnvVarsScriptPath $envVarsScript -ProfileName $InstallProfile

Write-Host 'Done.' -ForegroundColor Green

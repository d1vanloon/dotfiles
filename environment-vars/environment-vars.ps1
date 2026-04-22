<#
.SYNOPSIS
Applies environment variables and PATH entries for the current user.

.DESCRIPTION
Reads variable definitions and PATH entries from vars.json in this directory (common)
and from the profile-specific subdirectory (personal/ or work/). Profile-specific values
are merged on top of common values; profile-specific PATH entries are appended after
common PATH entries.

vars.json format:
{
  "variables": {
    "MY_VAR": "value"
  },
  "path": [
    "C:\\some\\path"
  ]
}

All changes are written to the CurrentUser / Machine scope (User by default) and take
effect in new shells. Existing PATH entries are not duplicated.

.PARAMETER InstallProfile
The profile to apply. Valid values are 'Personal' (default) and 'Work'.

.PARAMETER Scope
The environment variable scope to write to. Defaults to 'User'.

.EXAMPLE
./environment-vars.ps1

.EXAMPLE
./environment-vars.ps1 -InstallProfile Work
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
	[ValidateSet('Personal', 'Work')]
	[string]$InstallProfile = 'Personal',
	[ValidateSet('User', 'Machine')]
	[string]$Scope = 'User'
)

$ErrorActionPreference = 'Stop'

function Read-VarsFile {
	param([Parameter(Mandatory)] [string]$Path)

	if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
		return [PSCustomObject]@{ variables = [PSCustomObject]@{}; path = @() }
	}

	$data = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json

	if (-not $data.PSObject.Properties['variables']) {
		$data | Add-Member -NotePropertyName 'variables' -NotePropertyValue ([PSCustomObject]@{})
	}
	if (-not $data.PSObject.Properties['path']) {
		$data | Add-Member -NotePropertyName 'path' -NotePropertyValue @()
	}

	return $data
}

function Merge-VarsData {
	param(
		[Parameter(Mandatory)] [PSCustomObject]$Base,
		[Parameter(Mandatory)] [PSCustomObject]$Override
	)

	$merged = [PSCustomObject]@{
		variables = [PSCustomObject]@{}
		path      = @()
	}

	foreach ($prop in $Base.variables.PSObject.Properties) {
		$merged.variables | Add-Member -NotePropertyName $prop.Name -NotePropertyValue $prop.Value
	}
	foreach ($prop in $Override.variables.PSObject.Properties) {
		if ($merged.variables.PSObject.Properties[$prop.Name]) {
			$merged.variables.PSObject.Properties.Remove($prop.Name)
		}
		$merged.variables | Add-Member -NotePropertyName $prop.Name -NotePropertyValue $prop.Value
	}

	$merged.path = @($Base.path) + @($Override.path)

	return $merged
}

$commonVarsPath  = Join-Path $PSScriptRoot 'vars.json'
$profileVarsPath = Join-Path $PSScriptRoot $InstallProfile.ToLower() 'vars.json'

$commonData  = Read-VarsFile -Path $commonVarsPath
$profileData = Read-VarsFile -Path $profileVarsPath
$data        = Merge-VarsData -Base $commonData -Override $profileData

# Apply named environment variables
foreach ($prop in $data.variables.PSObject.Properties) {
	$name  = $prop.Name
	$value = $prop.Value

	if ($PSCmdlet.ShouldProcess("$Scope\$name = $value", 'Set environment variable')) {
		[System.Environment]::SetEnvironmentVariable($name, $value, $Scope)
		Write-Host "Set [$Scope] $name = $value" -ForegroundColor Cyan
	}
}

# Apply PATH entries
if ($data.path.Count -gt 0) {
	$currentPath = [System.Environment]::GetEnvironmentVariable('PATH', $Scope) ?? ''
	$existingEntries = $currentPath -split ';' | Where-Object { $_ -ne '' }

	$added = [System.Collections.Generic.List[string]]::new()

	foreach ($entry in $data.path) {
		$expanded = [System.Environment]::ExpandEnvironmentVariables($entry)
		$alreadyPresent = $existingEntries | Where-Object {
			$_.TrimEnd('\') -ieq $expanded.TrimEnd('\')
		}
		if (-not $alreadyPresent) {
			$added.Add($expanded)
		}
		else {
			Write-Verbose "PATH entry already present, skipping: $expanded"
		}
	}

	if ($added.Count -gt 0) {
		$newPath = ($existingEntries + $added) -join ';'
		if ($PSCmdlet.ShouldProcess("PATH (adding $($added.Count) entries)", "Set [$Scope] environment variable")) {
			[System.Environment]::SetEnvironmentVariable('PATH', $newPath, $Scope)
			foreach ($e in $added) {
				Write-Host "Added to [$Scope] PATH: $e" -ForegroundColor Cyan
			}
		}
	}
	else {
		Write-Verbose 'All PATH entries already present.'
	}
}

Write-Host "Environment variables applied for profile: $InstallProfile" -ForegroundColor Green

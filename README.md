# dotfiles

Windows-focused personal dotfiles and bootstrap scripts.

## What this repo manages

The repository is centered around `install.ps1`, which sets up a local machine by:

- linking the PowerShell profile, profile fragments, and Oh My Posh theme from `powershell/`
- installing PowerShell modules used by the profile
- linking a profile-specific Git config from `git/`
- installing bundled fonts from `fonts/`
- merging Windows Terminal settings from `terminal/`
- installing WinGet packages from `winget/`
- installing .NET global tools from `dotnet/`
- installing Visual Studio Professional Insiders from `visual-studio/`
- installing SQL Server Management Studio for the `Work` profile from `ssms/`
- applying common and profile-specific environment variables from `environment-vars/`

## Installation

Run from PowerShell:

- Default install: `./install.ps1`
- Replace existing linked or copied files: `./install.ps1 -Force`
- Use the work profile: `./install.ps1 -InstallProfile Work`

## Profiles

Two installation profiles are supported:

- `Personal` (default)
- `Work`

The selected profile controls which Git config, WinGet package list, .NET tool list, and environment variable overrides are applied.

## Repository layout

- `powershell/` - profile entrypoint, profile fragments, theme, and PowerShell module install script
- `git/` - profile-specific `.gitconfig` files
- `fonts/` - bundled fonts and installer
- `terminal/` - Windows Terminal settings merge script
- `winget/` - common and profile-specific WinGet package lists
- `dotnet/` - common and profile-specific .NET global tool lists
- `visual-studio/` - Visual Studio installation config
- `ssms/` - SQL Server Management Studio installation config
- `environment-vars/` - common and profile-specific environment variables and PATH entries

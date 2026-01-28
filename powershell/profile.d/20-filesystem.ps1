# Function for creating symbolic links
function New-Symlink {
    param(
        # Target of the link
        [Parameter(Mandatory = $true)]
        [string]
        $Target,
        # Name of the link
        [Parameter()]
        [string]
        $Name = (Split-Path $Target -Leaf)
    )
    New-Item -ItemType SymbolicLink -Name $Name -Target $Target
}

function Invoke-CreateAndEnterDirectory {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $DirectoryPath
    )

    # Create the directory if it doesn't exist
    if (-not (Test-Path -Path $DirectoryPath)) {
        New-Item -ItemType Directory -Path $DirectoryPath | Out-Null
    }

    # Enter the directory
    Set-Location -Path $DirectoryPath
}

Set-Alias -Name mkdir -Value Invoke-CreateAndEnterDirectory

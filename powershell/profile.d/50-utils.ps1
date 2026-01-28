# Quick cheat sheet access

function cheat {
    Param(
        # Query
        [Parameter(Mandatory = $true)]
        [string]
        $Query
    )
    curl cht.sh/$Query
}

# Activate local python venv

function pyact {
    $p = "./.venv/Scripts/Activate.ps1"
    if (Test-Path -Path $p) {
        & $p
    }
    else {
        Write-Error "Local venv not found."
    }
}

# Basic replacement for ssh-copy-id
function ssh-copy-id {
    [CmdletBinding(PositionalBinding = $false)]
    Param(
        # Connection details
        [Parameter(Mandatory = $true, Position = 0)]
        [string]
        $Connection,
        # Identity file
        [Parameter()]
        [string]
        $i,
        # Enable verbose output
        [switch]
        $v = $false
    )

    try {
        # Check to see if an identity file was provided
        if ("" -eq $i) {
            # No identity file; test ssh-agent output
            $agentOutput = ssh-add -L

            if ($null -eq $agentOutput) {
                # If no SSH agent output, use the default identity file
                if ($v) {
                    "Using identity file ~/.ssh/id_rsa.pub" | Write-Host
                }
                $identity = Get-Content "~/.ssh/id_rsa.pub" -ErrorAction Stop
            }
            else {
                # Use the output from the SSH agent
                if ($v) {
                    "Using output from ssh-agent" | Write-Host
                }
                $identity = $agentOutput
            }
        }
        else {
            # Use the provided identity file
            if ($v) {
                "Using identity file $i" | Write-Host
            }
            $identity = Get-Content $i  -ErrorAction Stop
        }

        # Append the identity information to the end of the authorized_keys file.
        # Note that this requires the ~/.ssh directory to exist
        $identity | ssh $Connection "cat >> ~/.ssh/authorized_keys"

        # Check to see if the operation was successful
        if ($LastExitCode -ne 0) {
            throw "Failed to copy identity to host."
        }

        "Copied identity to $Connection" | Write-Host
    }
    catch {
        "Could not copy ID." | Write-Error
        "Failed item: ${$_.Exception.ItemName}"
        "Exception: ${$_.Exception.Message}"
    }
}

# Helper function to show Unicode character
function U {
    param
    (
        [int] $Code
    )

    if ((0 -le $Code) -and ($Code -le 0xFFFF)) {
        return [char] $Code
    }

    if ((0x10000 -le $Code) -and ($Code -le 0x10FFFF)) {
        return [char]::ConvertFromUtf32($Code)
    }

    throw "Invalid character code $Code"
}

function Get-WeatherReport {
    & curl wttr.in
}

Set-Alias -Name weather -Value Get-WeatherReport

function Get-PublicIp {
    Invoke-WebRequest -Uri https://myip.wtf/text | Select-Object -ExpandProperty Content
}

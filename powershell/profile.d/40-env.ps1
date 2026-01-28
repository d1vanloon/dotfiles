# Helpers for modifying persistent environment variables

function Set-PersistentEnvVariable {
    Param(
        # Variable name
        [Parameter(Mandatory = $true)]
        [string]
        $VarName,
        # Variable value
        [Parameter(Mandatory = $true)]
        [string]
        $VarValue
    )
    [Environment]::SetEnvironmentVariable($VarName, $VarValue, [System.EnvironmentVariableTarget]::User)
    Set-Item -Path "env:$VarName" -Value $VarValue
}

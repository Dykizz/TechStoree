$ErrorActionPreference = 'Stop'

function Invoke-DockerChecked {
    param([string[]]$DockerArguments)
    $result = & docker @DockerArguments
    if ($LASTEXITCODE -ne 0) {
        throw "Docker failed (exit code $LASTEXITCODE): docker $($DockerArguments -join ' ')"
    }
    return $result
}

function Get-DatabaseSettings {
    param([string]$Container, [string]$Database, [string]$Username)
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        throw 'Docker CLI is required. Start Docker Desktop and the postgres service first.'
    }
    if (-not $Database) {
        $Database = (Invoke-DockerChecked -DockerArguments @('exec', $Container, 'printenv', 'POSTGRES_DB') | Out-String).Trim()
    }
    if (-not $Username) {
        $Username = (Invoke-DockerChecked -DockerArguments @('exec', $Container, 'printenv', 'POSTGRES_USER') | Out-String).Trim()
    }
    if (-not $Database -or -not $Username) { throw 'Database name and username must not be empty.' }
    return @{ Database = $Database; Username = $Username }
}

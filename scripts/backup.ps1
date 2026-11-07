[CmdletBinding()]
param(
    [string]$Container = 'webbanhang_postgres',
    [string]$Database,
    [string]$Username,
    [string]$OutputDirectory = (Join-Path $PSScriptRoot '../backups')
)

. (Join-Path $PSScriptRoot 'database-common.ps1')
$settings = Get-DatabaseSettings -Container $Container -Database $Database -Username $Username
$id = '{0}_{1}' -f (Get-Date -Format 'yyyyMMdd_HHmmss'), ([guid]::NewGuid().ToString('N').Substring(0, 8))
$temporaryFile = "/tmp/techstoree_$id.dump"
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$destination = Join-Path (Resolve-Path -LiteralPath $OutputDirectory).Path "backup_$id.dump"
$partial = "$destination.partial"
try {
    Invoke-DockerChecked -DockerArguments @('exec', $Container, 'pg_dump', '-U', $settings.Username, '-d', $settings.Database, '-F', 'c', '-b', '-f', $temporaryFile) | Out-Null
    Invoke-DockerChecked -DockerArguments @('exec', $Container, 'pg_restore', '--list', $temporaryFile) | Out-Null
    Invoke-DockerChecked -DockerArguments @('cp', "${Container}:$temporaryFile", $partial) | Out-Null
    if ((Get-Item -LiteralPath $partial).Length -eq 0) { throw 'The copied backup is empty.' }
    Move-Item -LiteralPath $partial -Destination $destination
    Write-Output "Backup created: $destination"
} finally {
    if (Test-Path -LiteralPath $partial) { Remove-Item -LiteralPath $partial }
    & docker exec $Container rm -f $temporaryFile
    if ($LASTEXITCODE -ne 0) { Write-Warning "Could not remove temporary file: $temporaryFile" }
}

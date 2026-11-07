[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$BackupFile,
    [ValidatePattern('^[a-z][a-z0-9_]{0,62}$')]
    [string]$TargetDatabase = ('techstoree_restore_test_' + (Get-Date -Format 'yyyyMMdd_HHmmss')),
    [string]$Container = 'webbanhang_postgres',
    [string]$Username
)

. (Join-Path $PSScriptRoot 'database-common.ps1')
$settings = Get-DatabaseSettings -Container $Container -Username $Username
if ($TargetDatabase -in @($settings.Database, 'web_ban_hang', 'postgres', 'template0', 'template1')) {
    throw 'Restoring into the application database or a system database is forbidden.'
}
$source = Get-Item -LiteralPath $BackupFile
if ($source.PSIsContainer -or $source.Length -eq 0) { throw 'BackupFile must be a non-empty archive file.' }
$temporaryFile = '/tmp/techstoree_restore_' + [guid]::NewGuid().ToString('N') + '.dump'
$created = $false
try {
    Invoke-DockerChecked -DockerArguments @('cp', $source.FullName, "${Container}:$temporaryFile") | Out-Null
    Invoke-DockerChecked -DockerArguments @('exec', $Container, 'pg_restore', '--list', $temporaryFile) | Out-Null
    # No DROP/overwrite: createdb fails if the target already exists.
    Invoke-DockerChecked -DockerArguments @('exec', $Container, 'createdb', '-U', $settings.Username, '--maintenance-db=postgres', $TargetDatabase) | Out-Null
    $created = $true
    Invoke-DockerChecked -DockerArguments @('exec', $Container, 'pg_restore', '-U', $settings.Username, '-d', $TargetDatabase, '--exit-on-error', '--single-transaction', $temporaryFile) | Out-Null
    Write-Output "Restore completed into a separate database: $TargetDatabase"
    Write-Output 'Verify tables and row counts in pgAdmin. The application connection has not been changed.'
} catch {
    if ($created) { Write-Warning "Restore failed. Test database '$TargetDatabase' remains for inspection; it is not a verified recovery." }
    throw
} finally {
    & docker exec $Container rm -f $temporaryFile
    if ($LASTEXITCODE -ne 0) { Write-Warning "Could not remove temporary file: $temporaryFile" }
}

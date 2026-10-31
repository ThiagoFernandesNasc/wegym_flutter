param(
  [string]$BackupDir = ${env:BACKUP_DIR},
  [int]$RetentionDays = ${env:RETENTION_DAYS},
  [string]$DbHost = ${env:DB_HOST},
  [int]$DbPort = ${env:DB_PORT},
  [string]$DbUser = ${env:DB_USER},
  [string]$DbName = ${env:DB_NAME},
  [string]$DbPassword = ${env:DB_PASSWORD}
)

if (-not $BackupDir) { $BackupDir = "/backups" }
if (-not $RetentionDays) { $RetentionDays = 7 }
if (-not $DbHost) { $DbHost = "db" }
if (-not $DbPort) { $DbPort = 5432 }
if (-not $DbUser) { $DbUser = "postgres" }
if (-not $DbName) { $DbName = "wegym" }

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$null = New-Item -ItemType Directory -Path $BackupDir -Force
$filename = Join-Path $BackupDir "wegym_${timestamp}.sql.gz"

Write-Host "-> Starting backup: $DbName@${DbHost}:${DbPort}"
Write-Host "-> Filename: $filename"

$env:PGPASSWORD = $DbPassword
$dumpArgs = @(
  "-h", $DbHost,
  "-p", $DbPort,
  "-U", $DbUser,
  "-d", $DbName,
  "--no-password"
)

& "pg_dump" $dumpArgs 2>&1 | & "gzip" --stdout 2>$null | Set-Content -Path $filename -AsByteStream

if ($LASTEXITCODE -eq 0) {
  $fileInfo = Get-Item $filename
  Write-Host "-> Backup saved: $filename ($([math]::Round($fileInfo.Length / 1MB, 2)) MB)"
} else {
  Write-Host "-> Backup FAILED"
  exit 1
}

Write-Host "-> Cleaning backups older than $RetentionDays days..."
$cutoff = (Get-Date).AddDays(-$RetentionDays)
Get-ChildItem -Path $BackupDir -Filter "wegym_*.sql.gz" | Where-Object { $_.LastWriteTime -lt $cutoff } | Remove-Item -Force

Write-Host "-> Backup complete."

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$backendRoot = Join-Path $projectRoot 'backend'
$nextCli = Join-Path $backendRoot 'node_modules\next\dist\bin\next'
$backendPort = 3000
$flutterPort = 7358
$backendProcess = $null
$startedBackend = $false
$logRoot = Join-Path $env:TEMP 'wegym-preview'
New-Item -ItemType Directory -Force -Path $logRoot | Out-Null
$stdoutLog = Join-Path $logRoot 'backend.log'
$stderrLog = Join-Path $logRoot 'backend-error.log'

function Test-PortInUse([int]$Port) {
  $connection = Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction SilentlyContinue | Select-Object -First 1
  return $null -ne $connection
}

try {
  if (-not (Test-PortInUse $backendPort)) {
    if (-not (Test-Path $nextCli)) { throw "Dependências do backend ausentes. Execute npm install na pasta backend." }
    Write-Host 'Iniciando backend Next.js em http://localhost:3000 ...'
    $backendProcess = Start-Process -FilePath (Get-Command node.exe).Source `
      -ArgumentList @($nextCli, 'dev', '--webpack', '--hostname', '127.0.0.1', '--port', "$backendPort") `
      -WorkingDirectory $backendRoot -WindowStyle Hidden -PassThru `
      -RedirectStandardOutput $stdoutLog -RedirectStandardError $stderrLog
    $startedBackend = $true
    $deadline = (Get-Date).AddSeconds(45)
    while ((Get-Date) -lt $deadline -and -not (Test-PortInUse $backendPort)) {
      if ($backendProcess.HasExited) {
        $details = if (Test-Path $stderrLog) { Get-Content $stderrLog -Raw } else { 'sem detalhes de erro' }
        throw "O backend encerrou durante a inicialização: $details"
      }
      Start-Sleep -Milliseconds 500
    }
    if (-not (Test-PortInUse $backendPort)) { throw "Backend não abriu a porta 3000 em 45 segundos. Logs: $logRoot" }
  } else {
    Write-Host 'Backend já está ativo na porta 3000; vou reutilizá-lo.'
  }

  Write-Host 'Abrindo prévia Flutter no Microsoft Edge ...'
  Push-Location $projectRoot
  try {
    & (Get-Command flutter.bat).Source run -d edge --web-port $flutterPort --dart-define=PREVIEW_DASHBOARD=true
    if ($LASTEXITCODE -ne 0) { throw "Flutter encerrou com código $LASTEXITCODE" }
  } finally {
    Pop-Location
  }
} finally {
  if ($startedBackend -and $backendProcess -and -not $backendProcess.HasExited) {
    Stop-Process -Id $backendProcess.Id -Force -ErrorAction SilentlyContinue
    Write-Host 'Backend iniciado por esta tarefa foi encerrado.'
  }
}

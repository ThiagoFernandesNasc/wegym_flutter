param(
  [string]$BackendRoot = '',
  [switch]$DeviceFrame = $true,
  [switch]$NoDeviceFrame,
  [int]$PreviewPort = 7358
)

$ErrorActionPreference = 'Stop'
$previousPreviewAiEnabled = $env:WEGYM_PREVIEW_AI_ENABLED
$env:WEGYM_PREVIEW_AI_ENABLED = 'true'
$projectRoot = Split-Path -Parent $PSScriptRoot
if (-not $BackendRoot) { $BackendRoot = Join-Path $projectRoot 'backend' }
$nextCli = Join-Path $backendRoot 'node_modules\next\dist\bin\next'
$backendPort = 3000
$flutterPort = $PreviewPort
if (-not $env:FLUTTER_APP_URL) { $env:FLUTTER_APP_URL = "http://localhost:$flutterPort" }
$backendProcess = $null
$startedBackend = $false
$browserJob = $null
$logRoot = Join-Path $env:TEMP 'wegym-preview'
New-Item -ItemType Directory -Force -Path $logRoot | Out-Null
$stdoutLog = Join-Path $logRoot 'backend.log'
$stderrLog = Join-Path $logRoot 'backend-error.log'

function Test-PortInUse([int]$Port) {
  $connection = Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($null -ne $connection) { return $true }
  $netstat = netstat -ano -p tcp 2>$null
  return [bool]($netstat | Where-Object {
    $_ -match "LISTENING\s+\d+$" -and $_ -match (":$Port\s")
  })
}

try {
  if (Test-PortInUse $flutterPort) { throw "Porta $flutterPort jÃ¡ estÃ¡ ocupada. Informe outra com -PreviewPort, por exemplo -PreviewPort 7359." }
  if (-not (Test-PortInUse $backendPort)) {
    if (-not (Test-Path $nextCli)) { throw "DependÃªncias do backend ausentes. Execute npm install na pasta backend." }
    if (-not $env:NEXTAUTH_URL -and -not (Test-Path (Join-Path $backendRoot '.env'))) { $env:NEXTAUTH_URL = 'http://localhost:3000' }
    if (-not $env:NEXTAUTH_SECRET -and -not (Test-Path (Join-Path $backendRoot '.env'))) { $env:NEXTAUTH_SECRET = 'wegym-local-demo-only-session-secret' }
    if (-not $env:DATABASE_URL -and -not (Test-Path (Join-Path $backendRoot '.env'))) {
      $env:DATABASE_URL = 'postgresql://postgres:password@127.0.0.1:5432/wegym?schema=public'
    }
    Write-Host "Iniciando backend Next.js do projeto Flutter em $backendRoot (porta 3000) ..."
    $backendProcess = Start-Process -FilePath (Get-Command node.exe).Source `
      -ArgumentList @($nextCli, 'dev', '--webpack', '--hostname', '127.0.0.1', '--port', "$backendPort") `
      -WorkingDirectory $backendRoot -WindowStyle Hidden -PassThru `
      -RedirectStandardOutput $stdoutLog -RedirectStandardError $stderrLog
    $startedBackend = $true
    $deadline = (Get-Date).AddSeconds(45)
    while ((Get-Date) -lt $deadline -and -not (Test-PortInUse $backendPort)) {
      if ($backendProcess.HasExited) {
        $details = if (Test-Path $stderrLog) { Get-Content $stderrLog -Raw } else { 'sem detalhes de erro' }
        throw "O backend encerrou durante a inicializaÃ§Ã£o: $details"
      }
      Start-Sleep -Milliseconds 500
    }
    if (-not (Test-PortInUse $backendPort)) { throw "Backend nÃ£o abriu a porta 3000 em 45 segundos. Logs: $logRoot" }
  } else {
    Write-Host 'Backend jÃ¡ estÃ¡ ativo na porta 3000; vou reutilizÃ¡-lo.'
  }

  $braveCommand = Get-Command brave.exe -ErrorAction SilentlyContinue | Select-Object -First 1
  $bravePath = if ($braveCommand) { $braveCommand.Source } else { $null }
  if (-not $bravePath) {
    $braveCandidates = @(
      "$env:ProgramFiles\BraveSoftware\Brave-Browser\Application\brave.exe",
      "${env:ProgramFiles(x86)}\BraveSoftware\Brave-Browser\Application\brave.exe",
      "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\Application\brave.exe"
    )
    $bravePath = $braveCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
  }
  if (-not $bravePath) { throw 'Brave nÃ£o foi encontrado neste computador.' }
  $browserJob = Start-Job -ArgumentList $flutterPort, $bravePath -ScriptBlock {
    param([int]$Port, [string]$BrowserPath)
    $url = "http://localhost:$Port"
    $deadline = (Get-Date).AddMinutes(1)
    while ((Get-Date) -lt $deadline) {
      try {
        $response = Invoke-WebRequest -UseBasicParsing -Uri $url -TimeoutSec 2
        if ($response.StatusCode -eq 200) {
          Start-Process -FilePath $BrowserPath -ArgumentList $url
          return
        }
      } catch { }
      Start-Sleep -Milliseconds 500
    }
    throw "Flutter nÃ£o abriu $url para o Brave."
  }

  Write-Host "Iniciando aplicativo Flutter para o navegador Brave em http://localhost:$flutterPort ..."
  Push-Location $projectRoot
  try {
    $flutterArgs = @(
      'run', '-d', 'web-server',
      '--web-hostname', '127.0.0.1',
      '--web-port', "$flutterPort",
      '--dart-define=PREVIEW_DASHBOARD=true',
      '--dart-define=PREVIEW_REQUIRE_LOGIN=true'
    )
    if ($DeviceFrame -and -not $NoDeviceFrame) {
      $flutterArgs += '--dart-define=DEVICE_FRAME_PREVIEW=true'
    }
    & (Get-Command flutter.bat).Source @flutterArgs
    if ($LASTEXITCODE -ne 0) { throw "Flutter encerrou com cÃ³digo $LASTEXITCODE" }
  } finally {
    Pop-Location
  }
} finally {
  if ($browserJob) {
    Stop-Job -Job $browserJob -ErrorAction SilentlyContinue
    Remove-Job -Job $browserJob -Force -ErrorAction SilentlyContinue
  }
  if ($startedBackend -and $backendProcess -and -not $backendProcess.HasExited) {
    Stop-Process -Id $backendProcess.Id -Force -ErrorAction SilentlyContinue
    Write-Host 'Backend iniciado por esta tarefa foi encerrado.'
  }
  if ($null -eq $previousPreviewAiEnabled) {
    Remove-Item Env:WEGYM_PREVIEW_AI_ENABLED -ErrorAction SilentlyContinue
  } else {
    $env:WEGYM_PREVIEW_AI_ENABLED = $previousPreviewAiEnabled
  }
}

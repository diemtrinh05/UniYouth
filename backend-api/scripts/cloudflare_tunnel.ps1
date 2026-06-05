param(
    [ValidateSet('start', 'stop', 'restart', 'status')]
    [string]$Action = 'status',

    [string]$TunnelId = $(if ($env:UNIYOUTH_TUNNEL_ID) { $env:UNIYOUTH_TUNNEL_ID } else { '' }),

    [string]$CloudflaredExe = $(if ($env:CLOUDFLARED_EXE) { $env:CLOUDFLARED_EXE } else { 'cloudflared' }),

    [string]$ConfigPath = ''
)

$ErrorActionPreference = 'Stop'

$RuntimeDir = Join-Path $PSScriptRoot '.runtime'
$PidFile = Join-Path $RuntimeDir 'cloudflared.pid'
$OutLog = Join-Path $RuntimeDir 'cloudflared.out.log'
$ErrLog = Join-Path $RuntimeDir 'cloudflared.err.log'

if ([string]::IsNullOrWhiteSpace($ConfigPath)) {
    $ConfigPath = if ([string]::IsNullOrWhiteSpace($TunnelId)) {
        Join-Path $PSScriptRoot 'cloudflared\config.generated.yml'
    } else {
        Join-Path $PSScriptRoot "cloudflared\$TunnelId.config.yml"
    }
}

function Resolve-ExecutablePath([string]$Executable) {
    if (Test-Path $Executable) {
        return $Executable
    }

    $command = Get-Command $Executable -ErrorAction SilentlyContinue
    if ($null -ne $command) {
        return $command.Source
    }

    return $Executable
}

function Ensure-RuntimeDir {
    if (-not (Test-Path $RuntimeDir)) {
        New-Item -ItemType Directory -Path $RuntimeDir | Out-Null
    }
}

function Get-TunnelPid {
    if (-not (Test-Path $PidFile)) {
        return $null
    }

    $pidText = (Get-Content $PidFile -Raw).Trim()
    if ([string]::IsNullOrWhiteSpace($pidText)) {
        return $null
    }

    $processId = 0
    if (-not [int]::TryParse($pidText, [ref]$processId)) {
        return $null
    }

    return $processId
}

function Stop-TunnelProcess {
    $processId = Get-TunnelPid
    if ($null -eq $processId) {
        Remove-Item $PidFile -Force -ErrorAction SilentlyContinue
        return
    }

    try {
        Stop-Process -Id $processId -Force -ErrorAction Stop
    }
    catch {
    }

    Remove-Item $PidFile -Force -ErrorAction SilentlyContinue
}

function Start-TunnelProcess {
    if ([string]::IsNullOrWhiteSpace($TunnelId)) {
        throw "Thiếu TunnelId. Hãy truyền -TunnelId hoặc set UNIYOUTH_TUNNEL_ID."
    }

    $resolvedCloudflaredExe = Resolve-ExecutablePath $CloudflaredExe
    if (-not (Test-Path $resolvedCloudflaredExe)) {
        throw "Không tìm thấy cloudflared. Hãy set CLOUDFLARED_EXE hoặc cài cloudflared vào PATH."
    }

    if (-not (Test-Path $ConfigPath)) {
        throw "Không tìm thấy config tunnel tại $ConfigPath"
    }

    Remove-Item $OutLog, $ErrLog -Force -ErrorAction SilentlyContinue

    $process = Start-Process `
        -FilePath $resolvedCloudflaredExe `
        -ArgumentList 'tunnel','--config',$ConfigPath,'run',$TunnelId `
        -RedirectStandardOutput $OutLog `
        -RedirectStandardError $ErrLog `
        -PassThru

    Set-Content -Path $PidFile -Value $process.Id
    Start-Sleep -Seconds 3

    if ($process.HasExited) {
        throw "Cloudflare tunnel thoát ngay sau khi start. Xem log: $ErrLog"
    }
}

function Show-Status {
    $processId = Get-TunnelPid
    $isRunning = $false
    $processName = ''
    $startTime = $null

    if ($null -ne $processId) {
        try {
            $proc = Get-Process -Id $processId -ErrorAction Stop
            $isRunning = $true
            $processName = $proc.ProcessName
            $startTime = $proc.StartTime
        }
        catch {
            Remove-Item $PidFile -Force -ErrorAction SilentlyContinue
        }
    }

    [pscustomobject]@{
        TunnelId = $TunnelId
        ConfigPath = $ConfigPath
        CloudflaredExe = Resolve-ExecutablePath $CloudflaredExe
        IsRunning = $isRunning
        ProcessId = if ($isRunning) { $processId } else { '' }
        ProcessName = $processName
        StartTime = $startTime
        OutLog = $OutLog
        ErrLog = $ErrLog
    } | Format-List
}

Ensure-RuntimeDir

switch ($Action) {
    'start' {
        Stop-TunnelProcess
        Start-TunnelProcess
        Show-Status
    }
    'stop' {
        Stop-TunnelProcess
        Show-Status
    }
    'restart' {
        Stop-TunnelProcess
        Start-TunnelProcess
        Show-Status
    }
    'status' {
        Show-Status
    }
}

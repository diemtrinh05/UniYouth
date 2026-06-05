param(
    [ValidateSet('start', 'stop', 'restart', 'status')]
    [string]$Action = 'start'
)

$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot
$RuntimeDir = Join-Path $PSScriptRoot '.runtime'
$DevSecretsScript = Join-Path $RepoRoot 'secrets\dev-runtime-env.ps1'
$FaceServiceDir = Join-Path $RepoRoot 'services\face-service'
$FacePython = Join-Path $FaceServiceDir '.python\python.exe'
$BackendProject = Join-Path $RepoRoot 'UniYouth.Api\UniYouth.Api.csproj'
$DefaultAdminRoot = Join-Path (Split-Path -Parent $RepoRoot) 'UniYouth.Admin'
$AdminRoot = if (-not [string]::IsNullOrWhiteSpace($env:UNIYOUTH_ADMIN_ROOT)) {
    $env:UNIYOUTH_ADMIN_ROOT
} elseif (Test-Path $DefaultAdminRoot) {
    $DefaultAdminRoot
} else {
    ''
}
$AdminProject = if ([string]::IsNullOrWhiteSpace($AdminRoot)) {
    ''
} else {
    Join-Path $AdminRoot 'UniYouth.Admin\UniYouth.Admin.csproj'
}
$FacePort = 8001
$ApiPort = 5160
$ApiHttpsPort = 7016
$AdminPort = 5036
$AdminHttpsPort = 7091
$FacePidFile = Join-Path $RuntimeDir 'face-service.pid'
$ApiPidFile = Join-Path $RuntimeDir 'uniyouth-api.pid'
$AdminPidFile = Join-Path $RuntimeDir 'uniyouth-admin.pid'
$FaceOutLog = Join-Path $RuntimeDir 'face-service.out.log'
$FaceErrLog = Join-Path $RuntimeDir 'face-service.err.log'
$ApiOutLog = Join-Path $RuntimeDir 'uniyouth-api.out.log'
$ApiErrLog = Join-Path $RuntimeDir 'uniyouth-api.err.log'
$AdminOutLog = Join-Path $RuntimeDir 'uniyouth-admin.out.log'
$AdminErrLog = Join-Path $RuntimeDir 'uniyouth-admin.err.log'

function Import-DevRuntimeSecrets {
    if (-not (Test-Path $DevSecretsScript)) {
        return
    }

    . $DevSecretsScript
}

function Ensure-RuntimeDir {
    if (-not (Test-Path $RuntimeDir)) {
        New-Item -ItemType Directory -Path $RuntimeDir | Out-Null
    }
}

function Get-ListeningPids([int]$Port) {
    try {
        @(Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction Stop |
            Select-Object -ExpandProperty OwningProcess -Unique)
    }
    catch {
        @()
    }
}

function Stop-PidIfRunning([string]$PidFile) {
    if (-not (Test-Path $PidFile)) {
        return
    }

    $pidText = (Get-Content $PidFile -Raw).Trim()
    if ([string]::IsNullOrWhiteSpace($pidText)) {
        Remove-Item $PidFile -Force -ErrorAction SilentlyContinue
        return
    }

    $processId = 0
    if (-not [int]::TryParse($pidText, [ref]$processId)) {
        Remove-Item $PidFile -Force -ErrorAction SilentlyContinue
        return
    }

    try {
        $process = Get-Process -Id $processId -ErrorAction Stop
        Stop-Process -Id $process.Id -Force -ErrorAction Stop
    }
    catch {
    }

    Remove-Item $PidFile -Force -ErrorAction SilentlyContinue
}

function Stop-PortListeners([int]$Port) {
    foreach ($processId in Get-ListeningPids -Port $Port) {
        try {
            Stop-Process -Id $processId -Force -ErrorAction Stop
        }
        catch {
        }
    }
}

function Wait-HttpReady([string]$Url, [int]$TimeoutSeconds = 60) {
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        try {
            $response = Invoke-WebRequest -Uri $Url -Method Get -UseBasicParsing -TimeoutSec 5
            if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 500) {
                return $true
            }
        }
        catch {
            Start-Sleep -Milliseconds 500
        }
    }

    return $false
}

function Wait-BackendReady([int]$TimeoutSeconds = 60) {
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        try {
            Invoke-WebRequest -Uri "http://localhost:$ApiPort/api/Users/me" -Method Get -UseBasicParsing -TimeoutSec 5 | Out-Null
        }
        catch {
            if ($_.Exception.Response -and [int]$_.Exception.Response.StatusCode -eq 401) {
                return $true
            }
            Start-Sleep -Milliseconds 500
        }
    }

    return $false
}

function Wait-BackendHttpsReady([int]$TimeoutSeconds = 60) {
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        try {
            $tcp = Test-NetConnection localhost -Port $ApiHttpsPort -WarningAction SilentlyContinue
            if ($tcp.TcpTestSucceeded) {
                return $true
            }
        }
        catch {
            Start-Sleep -Milliseconds 500
        }
    }

    return $false
}

function Wait-AdminReady([int]$TimeoutSeconds = 60) {
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        try {
            $response = Invoke-WebRequest -Uri "https://localhost:$AdminHttpsPort" -Method Get -UseBasicParsing -TimeoutSec 5
            if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 500) {
                return $true
            }
        }
        catch {
            Start-Sleep -Milliseconds 500
        }
    }

    return $false
}

function Start-FaceService {
    Import-DevRuntimeSecrets

    if (-not (Test-Path $FacePython)) {
        throw "Không tìm thấy Python embedded tại $FacePython"
    }

    Remove-Item $FaceOutLog, $FaceErrLog -Force -ErrorAction SilentlyContinue

    $process = Start-Process `
        -FilePath $FacePython `
        -ArgumentList '-m','uvicorn','app.main:app','--host','127.0.0.1','--port',"$FacePort" `
        -WorkingDirectory $FaceServiceDir `
        -RedirectStandardOutput $FaceOutLog `
        -RedirectStandardError $FaceErrLog `
        -PassThru

    Set-Content -Path $FacePidFile -Value $process.Id

    if (-not (Wait-HttpReady -Url "http://127.0.0.1:$FacePort/docs" -TimeoutSeconds 240)) {
        throw "Face service không khởi động được. Xem log: $FaceErrLog"
    }
}

function Start-Backend {
    Import-DevRuntimeSecrets
    Remove-Item $ApiOutLog, $ApiErrLog -Force -ErrorAction SilentlyContinue

    $process = Start-Process `
        -FilePath 'dotnet' `
        -ArgumentList 'run','-c','Release','--launch-profile','https','--project',$BackendProject `
        -WorkingDirectory $RepoRoot `
        -RedirectStandardOutput $ApiOutLog `
        -RedirectStandardError $ApiErrLog `
        -PassThru

    Set-Content -Path $ApiPidFile -Value $process.Id

    if (-not (Wait-BackendReady -TimeoutSeconds 90)) {
        throw "UniYouth.Api không khởi động được. Xem log: $ApiErrLog hoặc $ApiOutLog"
    }

    if (-not (Wait-BackendHttpsReady -TimeoutSeconds 90)) {
        throw "UniYouth.Api không mở được HTTPS tại https://localhost:$ApiHttpsPort. Xem log: $ApiErrLog hoặc $ApiOutLog"
    }
}

function Start-Admin {
    Import-DevRuntimeSecrets
    if (-not (Test-Path $AdminProject)) {
        throw "Không tìm thấy UniYouth.Admin project tại $AdminProject"
    }

    Remove-Item $AdminOutLog, $AdminErrLog -Force -ErrorAction SilentlyContinue

    $process = Start-Process `
        -FilePath 'dotnet' `
        -ArgumentList 'run','-c','Release','--launch-profile','https','--project',$AdminProject `
        -WorkingDirectory $AdminRoot `
        -RedirectStandardOutput $AdminOutLog `
        -RedirectStandardError $AdminErrLog `
        -PassThru

    Set-Content -Path $AdminPidFile -Value $process.Id

    if (-not (Wait-AdminReady -TimeoutSeconds 120)) {
        throw "UniYouth.Admin không khởi động được. Xem log: $AdminErrLog hoặc $AdminOutLog"
    }
}

function Show-Status {
    $faceUp = $false
    $apiUp = $false
    $apiHttpsUp = $false
    $adminUp = $false

    try {
        $faceUp = Wait-HttpReady -Url "http://127.0.0.1:$FacePort/docs" -TimeoutSeconds 2
    }
    catch {
    }

    try {
        $apiUp = Wait-BackendReady -TimeoutSeconds 2
    }
    catch {
    }

    try {
        $apiHttpsUp = Wait-BackendHttpsReady -TimeoutSeconds 2
    }
    catch {
    }

    try {
        $adminUp = Wait-AdminReady -TimeoutSeconds 2
    }
    catch {
    }

    [pscustomobject]@{
        FaceServiceUrl = "http://127.0.0.1:$FacePort"
        FaceServiceUp = $faceUp
        BackendUrl = "http://localhost:$ApiPort"
        BackendUp = $apiUp
        BackendHttpsUrl = "https://localhost:$ApiHttpsPort"
        BackendHttpsUp = $apiHttpsUp
        AdminUrl = "https://localhost:$AdminHttpsPort"
        AdminUp = $adminUp
        FaceServicePid = if (Test-Path $FacePidFile) { (Get-Content $FacePidFile -Raw).Trim() } else { '' }
        BackendPid = if (Test-Path $ApiPidFile) { (Get-Content $ApiPidFile -Raw).Trim() } else { '' }
        AdminPid = if (Test-Path $AdminPidFile) { (Get-Content $AdminPidFile -Raw).Trim() } else { '' }
        FaceServiceLog = $FaceOutLog
        BackendLog = $ApiOutLog
        AdminLog = $AdminOutLog
    } | Format-List
}

Ensure-RuntimeDir

switch ($Action) {
    'start' {
        Stop-PidIfRunning $FacePidFile
        Stop-PidIfRunning $ApiPidFile
        Stop-PidIfRunning $AdminPidFile
        Stop-PortListeners $FacePort
        Stop-PortListeners $ApiPort
        Stop-PortListeners $ApiHttpsPort
        Stop-PortListeners $AdminPort
        Stop-PortListeners $AdminHttpsPort
        Start-FaceService
        Start-Backend
        Start-Admin
        Show-Status
    }
    'stop' {
        Stop-PidIfRunning $AdminPidFile
        Stop-PidIfRunning $ApiPidFile
        Stop-PidIfRunning $FacePidFile
        Stop-PortListeners $AdminPort
        Stop-PortListeners $AdminHttpsPort
        Stop-PortListeners $ApiPort
        Stop-PortListeners $ApiHttpsPort
        Stop-PortListeners $FacePort
        Show-Status
    }
    'restart' {
        Stop-PidIfRunning $AdminPidFile
        Stop-PidIfRunning $ApiPidFile
        Stop-PidIfRunning $FacePidFile
        Stop-PortListeners $AdminPort
        Stop-PortListeners $AdminHttpsPort
        Stop-PortListeners $ApiPort
        Stop-PortListeners $ApiHttpsPort
        Stop-PortListeners $FacePort
        Start-FaceService
        Start-Backend
        Start-Admin
        Show-Status
    }
    'status' {
        Show-Status
    }
}


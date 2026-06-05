param(
    [ValidateSet('start', 'stop', 'restart', 'status')]
    [string]$Action = 'status'
)

$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot
$FaceStackScript = Join-Path $PSScriptRoot 'face_stack.ps1'
$TunnelScript = Join-Path $PSScriptRoot 'cloudflare_tunnel.ps1'
$DevSecretsScript = Join-Path $RepoRoot 'secrets\dev-runtime-env.ps1'

function Import-DevRuntimeSecrets {
    if (Test-Path $DevSecretsScript) {
        . $DevSecretsScript
    }
}

function Invoke-ManagedScript([string]$ScriptPath, [string]$ManagedAction) {
    if (-not (Test-Path $ScriptPath)) {
        throw "Không tìm thấy script tại $ScriptPath"
    }

    & powershell -ExecutionPolicy Bypass -File $ScriptPath $ManagedAction
}

Import-DevRuntimeSecrets

switch ($Action) {
    'start' {
        Invoke-ManagedScript $FaceStackScript 'start'
        Invoke-ManagedScript $TunnelScript 'start'
    }
    'stop' {
        Invoke-ManagedScript $TunnelScript 'stop'
        Invoke-ManagedScript $FaceStackScript 'stop'
    }
    'restart' {
        Invoke-ManagedScript $TunnelScript 'stop'
        Invoke-ManagedScript $FaceStackScript 'restart'
        Invoke-ManagedScript $TunnelScript 'start'
    }
    'status' {
        Write-Host '=== Local Stack ==='
        Invoke-ManagedScript $FaceStackScript 'status'
        Write-Host ''
        Write-Host '=== Cloudflare Tunnel ==='
        Invoke-ManagedScript $TunnelScript 'status'
    }
}

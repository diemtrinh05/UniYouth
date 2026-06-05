param(
    [ValidateSet('print', 'install', 'login', 'create', 'route', 'run')]
    [string]$Action = 'print',

    [string]$TunnelName = $(if ($env:UNIYOUTH_TUNNEL_NAME) { $env:UNIYOUTH_TUNNEL_NAME } else { 'uniyouth' }),

    [string]$Domain = $(if ($env:UNIYOUTH_PUBLIC_DOMAIN) { $env:UNIYOUTH_PUBLIC_DOMAIN } else { '' }),

    [string]$WindowsUser = $env:USERNAME,

    [string]$TunnelId = $(if ($env:UNIYOUTH_TUNNEL_ID) { $env:UNIYOUTH_TUNNEL_ID } else { '' }),

    [string]$ConfigPath = '',

    [string]$CredentialsPath = $(if ($env:CLOUDFLARED_CREDENTIALS_FILE) { $env:CLOUDFLARED_CREDENTIALS_FILE } else { '' })
)

$ErrorActionPreference = 'Stop'

$CloudflaredDir = Join-Path $PSScriptRoot 'cloudflared'
$TemplatePath = Join-Path $CloudflaredDir 'cloudflare.config.template.yml'

function Get-CloudflaredCommand {
    $command = Get-Command cloudflared -ErrorAction SilentlyContinue
    if ($null -eq $command) {
        throw "Chưa tìm thấy cloudflared trong PATH. Hãy cài cloudflared trước."
    }

    return $command.Source
}

function Require-Domain {
    if ([string]::IsNullOrWhiteSpace($Domain)) {
        throw "Thiếu domain public. Hãy truyền -Domain hoặc set UNIYOUTH_PUBLIC_DOMAIN."
    }
}

function Resolve-ConfigPath {
    param(
        [string]$TunnelUuid
    )

    if (-not [string]::IsNullOrWhiteSpace($ConfigPath)) {
        return $ConfigPath
    }

    if ([string]::IsNullOrWhiteSpace($TunnelUuid)) {
        return Join-Path $CloudflaredDir 'config.generated.yml'
    }

    return Join-Path $CloudflaredDir "$TunnelUuid.config.yml"
}

function Ensure-CloudflaredDir {
    if (-not (Test-Path $CloudflaredDir)) {
        New-Item -ItemType Directory -Path $CloudflaredDir | Out-Null
    }
}

function Write-GeneratedConfig {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TunnelUuid
    )

    Require-Domain
    Ensure-CloudflaredDir

    $targetPath = Resolve-ConfigPath -TunnelUuid $TunnelUuid
    $resolvedCredentialsPath = if ([string]::IsNullOrWhiteSpace($CredentialsPath)) {
        Join-Path $HOME ".cloudflared\$TunnelUuid.json"
    } else {
        $CredentialsPath
    }

    $content = Get-Content $TemplatePath -Raw
    $content = $content.Replace('<TUNNEL_UUID>', $TunnelUuid)
    $content = $content.Replace('<YOUR_WINDOWS_USER>', $WindowsUser)
    $content = $content.Replace('<CLOUDFLARED_CREDENTIALS_FILE>', $resolvedCredentialsPath)
    $content = $content.Replace('<DOMAIN>', $Domain.Trim())

    Set-Content -Path $targetPath -Value $content -Encoding UTF8
    return $targetPath
}

function Print-Steps {
    $domainDisplay = if ([string]::IsNullOrWhiteSpace($Domain)) { '<YOUR_DOMAIN>' } else { $Domain }

    Write-Host "Domain        : $domainDisplay"
    Write-Host "Tunnel name   : $TunnelName"
    Write-Host "Template file : $TemplatePath"
    Write-Host ""
    Write-Host "Bước 1 - Cài cloudflared:"
    Write-Host "  winget install --id Cloudflare.cloudflared -e"
    Write-Host ""
    Write-Host "Bước 2 - Login Cloudflare:"
    Write-Host "  cloudflared tunnel login"
    Write-Host ""
    Write-Host "Bước 3 - Tạo tunnel:"
    Write-Host "  cloudflared tunnel create $TunnelName"
    Write-Host ""
    Write-Host "Bước 4 - Sau khi có Tunnel UUID, sinh config:"
    Write-Host "  .\scripts\setup_cloudflare_tunnel.ps1 -Action create -Domain $domainDisplay -TunnelName $TunnelName -TunnelId <TUNNEL_UUID>"
    Write-Host ""
    Write-Host "Bước 5 - Tạo DNS routes:"
    Write-Host "  cloudflared tunnel route dns <TUNNEL_UUID> api.$domainDisplay"
    Write-Host "  cloudflared tunnel route dns <TUNNEL_UUID> admin.$domainDisplay"
    Write-Host "  cloudflared tunnel route dns <TUNNEL_UUID> face.$domainDisplay"
    Write-Host ""
    Write-Host "Bước 6 - Chạy tunnel:"
    Write-Host "  cloudflared tunnel --config scripts\cloudflared\<TUNNEL_UUID>.config.yml run <TUNNEL_UUID>"
}

switch ($Action) {
    'print' {
        Print-Steps
    }

    'install' {
        winget install --id Cloudflare.cloudflared -e
    }

    'login' {
        $cloudflared = Get-CloudflaredCommand
        & $cloudflared tunnel login
    }

    'create' {
        Require-Domain
        $cloudflared = Get-CloudflaredCommand

        if ([string]::IsNullOrWhiteSpace($TunnelId)) {
            $createOutput = & $cloudflared tunnel create $TunnelName 2>&1
            $createText = ($createOutput | Out-String)
            Write-Host $createText

            $uuidMatch = [regex]::Match($createText, '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}')
            if (-not $uuidMatch.Success) {
                throw "Không parse được Tunnel UUID từ output cloudflared. Hãy truyền -TunnelId thủ công."
            }

            $TunnelId = $uuidMatch.Value
        }

        $generated = Write-GeneratedConfig -TunnelUuid $TunnelId
        Write-Host "Đã tạo config: $generated"
        Write-Host "Tunnel UUID   : $TunnelId"
        Write-Host "Domain        : $Domain"
    }

    'route' {
        Require-Domain
        if ([string]::IsNullOrWhiteSpace($TunnelId)) {
            throw "Thiếu -TunnelId"
        }

        $cloudflared = Get-CloudflaredCommand
        & $cloudflared tunnel route dns $TunnelId "api.$Domain"
        & $cloudflared tunnel route dns $TunnelId "admin.$Domain"
        & $cloudflared tunnel route dns $TunnelId "face.$Domain"
    }

    'run' {
        if ([string]::IsNullOrWhiteSpace($TunnelId)) {
            throw "Thiếu -TunnelId"
        }

        $cloudflared = Get-CloudflaredCommand
        $resolvedConfigPath = Resolve-ConfigPath -TunnelUuid $TunnelId

        if (-not (Test-Path $resolvedConfigPath)) {
            throw "Không tìm thấy config tunnel tại $resolvedConfigPath"
        }

        & $cloudflared tunnel --config $resolvedConfigPath run $TunnelId
    }
}

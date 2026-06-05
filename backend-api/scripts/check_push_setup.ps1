param()

$root = Split-Path -Parent $PSScriptRoot
$configPath = Join-Path $root 'UniYouth.Api\appsettings.Development.json'
if (-not (Test-Path $configPath)) {
    Write-Error "Không tìm thấy $configPath"
    exit 1
}

$config = Get-Content $configPath -Raw | ConvertFrom-Json
$fcm = $config.PushNotifications.Fcm

function Resolve-ConfigValue([string]$EnvName, [object]$FallbackValue) {
    $envValue = [Environment]::GetEnvironmentVariable($EnvName)
    if (-not [string]::IsNullOrWhiteSpace($envValue)) {
        return $envValue
    }

    return [string]$FallbackValue
}

$projectId = Resolve-ConfigValue 'PushNotifications__Fcm__ProjectId' $fcm.ProjectId
$serviceAccountPath = Resolve-ConfigValue 'PushNotifications__Fcm__ServiceAccountJsonPath' $fcm.ServiceAccountJsonPath
$hasServiceAccountPath = -not [string]::IsNullOrWhiteSpace($serviceAccountPath)

Write-Host "FCM Enabled        : $($fcm.Enabled)"
Write-Host "FCM ProjectId      : $projectId"
Write-Host "ServiceAccountPath : $serviceAccountPath"
Write-Host "ServiceAccountFile : $(if ($hasServiceAccountPath) { Test-Path $serviceAccountPath } else { $false })"

if (-not $hasServiceAccountPath -or -not (Test-Path $serviceAccountPath)) {
    Write-Warning "Thiếu file service account. Hãy đặt file JSON vào đường dẫn trên hoặc override bằng env PushNotifications__Fcm__ServiceAccountJsonPath."
    Write-Warning "Có thể tham khảo scripts\\dev-runtime-env.example.ps1 và copy thành secrets\\dev-runtime-env.ps1."
    exit 2
}

try {
    $json = Get-Content $serviceAccountPath -Raw | ConvertFrom-Json
    Write-Host "Client Email       : $($json.client_email)"
    Write-Host "Project Id (json)  : $($json.project_id)"
}
catch {
    Write-Error "Không đọc được JSON service account: $($_.Exception.Message)"
    exit 3
}

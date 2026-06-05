$apiBaseUrl = 'http://localhost:5160'
$adminBaseUrl = 'https://localhost:7091'

$env:Jwt__Key = 'REPLACE_WITH_A_LONG_RANDOM_SECRET_AT_LEAST_32_CHARS'
$env:ConnectionStrings__UniYouth = 'Data Source=localhost;Initial Catalog=UniYouth;Integrated Security=True;Trust Server Certificate=True'
$env:PublicBaseUrl = $apiBaseUrl
$env:PasswordReset__PublicResetBaseUrl = $adminBaseUrl

# Admin Web
$env:ApiSettings__BaseUrl = $apiBaseUrl
$env:ApiSettings__PublicBaseUrl = $apiBaseUrl
$env:ApiSettings__AssetBaseUrl = $apiBaseUrl
$env:JwtSettings__SecretKey = $env:Jwt__Key
$env:UNIYOUTH_ADMIN_ROOT = ''

# SMTP / Email
$env:Email__From__Name = 'UniYouth'
$env:Email__From__Email = 'your-email@example.com'
$env:Email__Smtp__Username = 'your-email@example.com'
$env:Email__Smtp__Password = 'REPLACE_WITH_SMTP_APP_PASSWORD'

# Gmail API (optional)
$env:Email__Gmail__UserEmail = 'your-email@example.com'
$env:Email__Gmail__ClientId = ''
$env:Email__Gmail__ClientSecret = ''
$env:Email__Gmail__RefreshToken = ''

# Firebase Push (optional)
$env:PushNotifications__Fcm__ProjectId = 'product-40717'
$env:PushNotifications__Fcm__ServiceAccountJsonPath = Join-Path $PSScriptRoot 'firebase-service-account.json'

# Cloudflare tunnel (optional)
$env:UNIYOUTH_PUBLIC_DOMAIN = ''
$env:UNIYOUTH_TUNNEL_NAME = 'uniyouth'
$env:UNIYOUTH_TUNNEL_ID = ''
$env:CLOUDFLARED_EXE = 'cloudflared'
$env:CLOUDFLARED_CREDENTIALS_FILE = ''

# Face detector backend
$env:FACE_SERVICE_DETECTOR_BACKEND = 'opencv'
$env:FACE_SERVICE_VERIFY_DETECTOR_BACKEND = 'yunet'
$env:FACE_SERVICE_ENROLL_DETECTOR_BACKEND = 'opencv'
$env:LIVENESS_SERVICE_DETECTOR_BACKEND = 'yunet'

# APNS (optional)
$env:PushNotifications__Apns__PrivateKeyPath = ''

Write-Host 'Đã nạp biến môi trường dev runtime cho UniYouth.'
Write-Host 'API URL dùng cho API, ảnh và file upload:' $apiBaseUrl
Write-Host 'Admin URL dùng cho link đặt lại mật khẩu:' $adminBaseUrl
Write-Host 'Cách dùng: copy file này thành secrets\dev-runtime-env.ps1 rồi sửa giá trị thật.'
Write-Host 'Sau đó chạy scripts\face_stack.ps1 hoặc scripts\public_stack.ps1 như bình thường.'

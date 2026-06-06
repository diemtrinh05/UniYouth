# UniYouth

## Overview

UniYouth là hệ thống quản lý hoạt động đoàn hội và điểm rèn luyện. Repo này là monorepo public, gồm 3 phần chính: Backend API, Web Admin và Mobile App. Hệ thống hỗ trợ quản lý sự kiện, đăng ký tham gia, điểm hoạt động, điểm danh bằng QR/GPS/khuôn mặt, thông báo, hỗ trợ người dùng và báo cáo quản trị.

Repo public này không chứa secret, file cấu hình runtime cá nhân, build output, cache, virtualenv, APK hoặc các file nằm trong `.gitignore`.

## Features

- Đăng nhập bằng tài khoản nội bộ, JWT access token và refresh token.
- Quên mật khẩu, xác thực OTP và đặt lại mật khẩu.
- Quản lý người dùng, hồ sơ cá nhân, avatar, vai trò và trạng thái tài khoản.
- Quản lý đơn vị, viện, chức vụ và phân quyền theo vai trò.
- Quản lý loại sự kiện, sự kiện, ảnh sự kiện, trạng thái sự kiện và địa điểm.
- Đăng ký và hủy đăng ký tham gia sự kiện.
- Sinh, xem chi tiết và vô hiệu hóa QR code điểm danh.
- Điểm danh sự kiện bằng QR code, GPS, device id, xác thực khuôn mặt và passive liveness.
- Quản lý điểm hoạt động và lịch sử điểm của người dùng.
- Báo cáo điểm danh, thống kê sự kiện, telemetry sinh trắc học và observability thông báo.
- Hộp thư thông báo, số lượng chưa đọc, đánh dấu đã đọc và đánh dấu tất cả đã đọc.
- Push notification qua FCM/APNS theo cấu hình runtime.
- Realtime notification và support chat qua SignalR.
- Web Admin cho cán bộ/admin: dashboard, sự kiện, QR, điểm danh, người dùng, báo cáo, notification và support chat.
- Mobile app cho người dùng: đăng nhập, sự kiện, đăng ký, điểm danh QR, lịch sử điểm danh, điểm, thông báo, hồ sơ và hỗ trợ.
- Python face-service nội bộ dùng DeepFace/ArcFace để enroll, verify và liveness check.

## Tech Stack

### Backend API

- C# / .NET 8
- ASP.NET Core Web API
- Entity Framework Core 8
- SQL Server
- JWT Bearer Authentication
- ASP.NET Core Authorization Roles
- ASP.NET Core Rate Limiting
- SignalR
- Swagger / Swashbuckle
- BCrypt.Net-Next
- Google Gmail API client
- SMTP email
- FCM/APNS push notification integration
- xUnit, Moq, EF Core InMemory cho test

### Web Admin

- C# / .NET 8
- ASP.NET Core MVC / Razor Views
- HttpClient-based API services
- JWT validation từ HttpOnly cookie
- QRCoder
- HTML/CSS/JavaScript

### Mobile App

- Flutter
- Dart SDK `^3.10.7`
- Riverpod
- Dio
- Flutter Secure Storage
- Shared Preferences
- Firebase Core
- Firebase Messaging
- Flutter Local Notifications
- SignalR client
- Mobile Scanner
- Geolocator
- Camera
- Google ML Kit Face Detection
- Image Picker / File Picker
- Permission Handler

### Face Service

- Python 3.11+
- FastAPI
- Uvicorn
- DeepFace
- TensorFlow/Keras qua `tf-keras`
- NumPy
- Pillow

## Architecture

Repo này là monorepo gồm 3 ứng dụng chính và 1 service Python nội bộ:

```text
Flutter Mobile App
        |
        | HTTP API + SignalR
        v
ASP.NET Core Backend API  <---->  SQL Server
        |
        | HTTP internal endpoints
        v
Python FastAPI Face Service

ASP.NET Core Web Admin
        |
        | HTTP API + SignalR
        v
ASP.NET Core Backend API
```

Backend API là monolithic layered architecture:

- `Controllers`: nhận HTTP request và trả API response.
- `Application/Services`: xử lý business logic.
- `Contracts/DTOs`: request/response DTO.
- `Domain/Entities`: entity ánh xạ database.
- `Infrastructure/Data`: EF Core DbContext và mapping.
- `Shared`: constants, enums, exception handling, helpers, idempotency, push notification và face verification options.

Mobile app đi theo hướng Clean Architecture/feature-based:

- `core`: network, storage, auth, error handling, notification, permission, device, location.
- `data`: remote datasource, model, repository implementation.
- `domain`: entity, repository contract, use case.
- `presentation`: screen, state, router, Riverpod providers.

Web Admin là MVC layered client:

- `Controllers`: xử lý route web.
- `Services`: gọi Backend API bằng HttpClient.
- `Models`: DTO và ViewModel.
- `Views`: Razor UI.
- `Filters`: global admin authorization filter.
- `Helpers`: JWT, cookie, asset URL, datetime helpers.

## Project Structure

```text
UniYouth/
├── backend-api/
│   ├── UniYouth.Api.sln
│   ├── UniYouth.Api/
│   │   ├── Application/
│   │   │   ├── Hubs/
│   │   │   ├── Jobs/
│   │   │   ├── Services/
│   │   │   └── Templates/
│   │   ├── Contracts/DTOs/
│   │   ├── Controllers/
│   │   ├── Domain/Entities/
│   │   ├── Infrastructure/Data/
│   │   ├── Shared/
│   │   ├── Program.cs
│   │   └── appsettings.json
│   ├── UniYouth.Api.Tests/
│   ├── DatabaseScripts/
│   ├── scripts/
│   └── services/face-service/
│       ├── app/main.py
│       ├── requirements.txt
│       └── .env.example
├── web-admin/
│   ├── UniYouth.Admin.sln
│   └── UniYouth.Admin/
│       ├── Controllers/
│       ├── Filters/
│       ├── Helpers/
│       ├── Models/
│       ├── Services/
│       ├── Views/
│       ├── wwwroot/
│       ├── Program.cs
│       └── appsettings.json
├── mobile-app/
│   ├── lib/
│   │   ├── core/
│   │   ├── data/
│   │   ├── domain/
│   │   ├── presentation/
│   │   ├── services/
│   │   └── main.dart
│   ├── test/
│   ├── android/
│   ├── ios/
│   ├── web/
│   ├── windows/
│   ├── linux/
│   ├── macos/
│   └── pubspec.yaml
└── README.md
```

## Prerequisites

- Git
- .NET SDK 8
- SQL Server 2022 hoặc SQL Server tương thích với database compatibility level 160
- Flutter SDK hỗ trợ Dart `^3.10.7`
- Android Studio / Android SDK nếu chạy Android
- Xcode nếu chạy iOS/macOS
- Python 3.11+
- PowerShell nếu dùng script trong `backend-api/scripts`
- Firebase project/service account nếu bật FCM push notification
- SMTP hoặc Gmail API credentials nếu bật email
- Cloudflare Tunnel nếu dùng public tunnel script

## Installation

Clone project:

```bash
git clone https://github.com/diemtrinh05/UniYouth.git
cd UniYouth
```

Restore backend:

```bash
cd backend-api
dotnet restore
```

Restore web admin:

```bash
cd ../web-admin
dotnet restore
```

Restore mobile app:

```bash
cd ../mobile-app
flutter pub get
```

Tạo Python environment cho face-service:

```bash
cd ../backend-api/services/face-service
python -m venv .venv
```

Windows PowerShell:

```powershell
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

macOS/Linux:

```bash
source .venv/bin/activate
pip install -r requirements.txt
```

## Configuration

Cấu hình runtime trong source public đang để trống có chủ đích. Hãy dùng environment variables, user-secrets hoặc file local không commit.

### Backend API

File cấu hình:

```text
backend-api/UniYouth.Api/appsettings.json
```

Các key quan trọng:

```env
ConnectionStrings__UniYouth=
Jwt__Key=
Jwt__Issuer=UniYouth.Api
Jwt__Audience=UniYouth.Client
Jwt__ExpireMinutes=480
Jwt__RefreshTokenExpireDays=30
PublicBaseUrl=
PasswordReset__PublicResetBaseUrl=
FaceVerification__Service__BaseUrl=
FaceVerification__Service__TimeoutSeconds=3
Email__From__Name=UniYouth
Email__From__Email=
Email__Smtp__Host=smtp.gmail.com
Email__Smtp__Port=587
Email__Smtp__Username=
Email__Smtp__Password=
Email__Gmail__Enabled=false
Email__Gmail__UserEmail=
Email__Gmail__ClientId=
Email__Gmail__ClientSecret=
Email__Gmail__RefreshToken=
PushNotifications__Fcm__Enabled=false
PushNotifications__Fcm__ProjectId=
PushNotifications__Fcm__ServiceAccountJsonPath=
PushNotifications__Apns__Enabled=false
PushNotifications__Apns__TeamId=
PushNotifications__Apns__KeyId=
PushNotifications__Apns__BundleId=
PushNotifications__Apns__PrivateKeyPath=
Cors__AllowedOrigins__0=
```

Ví dụ cấu hình local bằng PowerShell:

```powershell
$env:ConnectionStrings__UniYouth = 'Data Source=localhost;Initial Catalog=UniYouth;Integrated Security=True;Trust Server Certificate=True'
$env:Jwt__Key = 'REPLACE_WITH_A_LONG_RANDOM_SECRET_AT_LEAST_32_CHARS'
$env:PublicBaseUrl = 'http://localhost:5160'
$env:PasswordReset__PublicResetBaseUrl = 'https://localhost:7091'
$env:FaceVerification__Service__BaseUrl = 'http://127.0.0.1:8001'
```

### Web Admin

File cấu hình:

```text
web-admin/UniYouth.Admin/appsettings.json
```

Các key quan trọng:

```env
ApiSettings__BaseUrl=http://localhost:5160
ApiSettings__PublicBaseUrl=http://localhost:5160
ApiSettings__AssetBaseUrl=http://localhost:5160
ApiSettings__Timeout=30
JwtSettings__SecretKey=
JwtSettings__Issuer=UniYouth.Api
JwtSettings__Audience=UniYouth.Client
GoogleMaps__ApiKey=
CookieSettings__Secure=false
CookieSettings__SameSite=Strict
```

`JwtSettings__SecretKey` phải trùng với `Jwt__Key` của backend.

### Mobile App

Mobile API config được xử lý tại:

```text
mobile-app/lib/services/config/api_config_service.dart
```

Các dart define được hỗ trợ:

```env
APP_ENV=dev|staging|prod
API_BASE_URL=
```

Quy tắc trong source:

- `APP_ENV` mặc định là `dev`.
- Dev mode mặc định dùng `http://localhost:5160`.
- Dev mode có thể lưu IP backend trong màn hình cấu hình API của app.
- `staging` và `prod` bắt buộc có `API_BASE_URL`.
- Bản build production không cho phép loopback host như `localhost`, `127.0.0.1`, `::1`, `10.0.2.2`.

Ví dụ:

```bash
flutter run --dart-define=APP_ENV=dev --dart-define=API_BASE_URL=http://localhost:5160
flutter run --dart-define=APP_ENV=staging --dart-define=API_BASE_URL=https://api.example.com
flutter run --release --dart-define=APP_ENV=prod --dart-define=API_BASE_URL=https://api.example.com
```

Cần cấu hình thủ công:

- Repo public không có Firebase platform files.
- Nếu cần push notification, hãy thêm file Firebase đúng cho Android/iOS.

### Face Service

File cấu hình mẫu:

```text
backend-api/services/face-service/.env.example
```

Các biến quan trọng:

```env
FACE_SERVICE_PROVIDER=DeepFace
FACE_SERVICE_MODEL=ArcFace
FACE_SERVICE_VERSION=poc-v1-dev
FACE_SERVICE_TIMEOUT_SECONDS=3
FACE_SERVICE_DETECTOR_BACKEND=opencv
FACE_SERVICE_VERIFY_DETECTOR_BACKEND=yunet
FACE_SERVICE_ENROLL_DETECTOR_BACKEND=opencv
FACE_SERVICE_MATCH_THRESHOLD=0.85
FACE_SERVICE_REVIEW_THRESHOLD=0.70
FACE_SERVICE_BLURRY_VARIANCE_THRESHOLD=20
FACE_SERVICE_MAX_IMAGE_DIMENSION=640
LIVENESS_SERVICE_PROVIDER=PassiveLiveness
LIVENESS_SERVICE_MODEL=rule-based-passive-burst-v1
LIVENESS_SERVICE_VERSION=phase3-v1
LIVENESS_SERVICE_TIMEOUT_SECONDS=3
LIVENESS_FRAME_COUNT=3
LIVENESS_FRAME_MAX_KB=150
LIVENESS_BURST_MAX_KB=450
LIVENESS_PASS_THRESHOLD=0.60
LIVENESS_REVIEW_THRESHOLD=0.35
```

## Database Setup

Database engine: SQL Server.

Các script chính nằm trong:

```text
backend-api/DatabaseScripts/
```

Repo public có các script SQL đầy đủ như:

- `UniYouth.sql`
- `UniYouth_v2.sql`
- `UniYouth_v3.sql`
- `UniYouth_v4.sql`
- Các script incremental theo ngày trong `DatabaseScripts/`

`UniYouth.sql` tạo database `[UniYouth]` và drop database cùng tên nếu đã tồn tại. Hãy đọc kỹ script trước khi chạy trên máy có dữ liệu thật.

Ví dụ tạo database bằng SQL Server:

```sql
CREATE DATABASE UniYouth;
```

Sau đó chạy script schema/data phù hợp với môi trường của bạn. Repo hiện không có EF Core migration files, nên setup database đang dựa trên SQL script.

Cần cấu hình thủ công:

- Xác định script SQL chuẩn dùng để khởi tạo database cho môi trường dev.
- Kiểm tra tài khoản admin/cán bộ/sinh viên seed trong script trước lần đăng nhập đầu tiên.
- Cấu hình `ConnectionStrings__UniYouth` trỏ đến database đã tạo.

## Running Project

### Development

Chạy face-service:

```bash
cd backend-api/services/face-service
python -m uvicorn app.main:app --host 127.0.0.1 --port 8001
```

Chạy backend API:

```bash
cd backend-api
dotnet run --project UniYouth.Api --launch-profile http
```

URL mặc định của backend trong `launchSettings.json`:

```text
http://localhost:5160
https://localhost:7016
```

Chạy web admin:

```bash
cd web-admin
dotnet run --project UniYouth.Admin --launch-profile https
```

URL mặc định của admin trong `launchSettings.json`:

```text
http://localhost:5036
https://localhost:7091
```

Chạy mobile app:

```bash
cd mobile-app
flutter run --dart-define=APP_ENV=dev --dart-define=API_BASE_URL=http://localhost:5160
```

Ghi chú cho Android emulator:

- Source mặc định dùng `localhost` trong dev mode.
- Nếu emulator không gọi được backend, dùng màn hình dev API config trong app hoặc truyền host có thể truy cập được.
- Với Android emulator, `10.0.2.2` thường trỏ về localhost của máy host.

### Optional PowerShell Scripts

Các script nằm trong:

```text
backend-api/scripts/
```

Script đáng chú ý:

- `face_stack.ps1`: start/stop face-service, API và admin trong layout repo riêng cũ.
- `public_stack.ps1`: chạy local stack kèm Cloudflare tunnel.
- `dev-runtime-env.example.ps1`: biến môi trường mẫu.
- `setup_cloudflare_tunnel.ps1`: hỗ trợ thiết lập Cloudflare tunnel.

Cần cấu hình thủ công:

- Các script này được viết theo layout admin nằm ở repo sibling. Trong monorepo này, nếu dùng script hãy set `UNIYOUTH_ADMIN_ROOT` đến đường dẫn tuyệt đối của `web-admin`.
- Copy `dev-runtime-env.example.ps1` thành file local không commit trước khi điền giá trị thật.

### Production

Cần cấu hình thủ công:

- Repo hiện không có Dockerfile hoặc `docker-compose.yml`.
- Hosting production cần tự cấu hình cho API, Admin, SQL Server, face-service và HTTPS public routing.

## Build

Backend API:

```bash
cd backend-api
dotnet build
dotnet publish UniYouth.Api -c Release -o publish/api
```

Web Admin:

```bash
cd web-admin
dotnet build
dotnet publish UniYouth.Admin -c Release -o publish/admin
```

Mobile:

```bash
cd mobile-app
flutter build apk --dart-define=APP_ENV=prod --dart-define=API_BASE_URL=https://api.example.com
```

Repo có các target Flutter `android`, `ios`, `web`, `windows`, `linux`, `macos`, nhưng signing/build settings theo từng platform cần cấu hình thủ công.

Kiểm tra cú pháp face-service:

```bash
cd backend-api/services/face-service
python -m compileall app tools
```

## API Documentation

Swagger chỉ bật trong môi trường phát triển (`Development`) và được mount ở root của API:

```text
http://localhost:5160/
http://localhost:5160/swagger/v1/swagger.json
```

Các nhóm endpoint chính trong controllers:

- `POST /api/Auth/login`
- `POST /api/Auth/refresh`
- `POST /api/Auth/revoke`
- `GET /api/Auth/health`
- `POST /api/Auth/forgot-password`
- `POST /api/Auth/verify-reset-otp`
- `POST /api/Auth/reset-password`
- `GET /api/Users/me`
- `PUT /api/Users/me`
- `POST /api/Users/change-password`
- `POST /api/Users/me/avatar`
- `DELETE /api/Users/me/avatar`
- `POST /api/Users/me/face-profile/re-auth-otp`
- `POST /api/Users/me/face-profile`
- `GET /api/events`
- `GET /api/events/admin`
- `GET /api/events/{id}`
- `POST /api/events`
- `PUT /api/events/{id}`
- `PUT /api/events/{id}/close`
- `PUT /api/events/{id}/cancel`
- `POST /api/events/{eventId}/register`
- `DELETE /api/events/{eventId}/register`
- `GET /api/events/{eventId}/my-registration`
- `POST /api/events/{eventId}/qrcode`
- `GET /api/events/{eventId}/qrcode`
- `PUT /api/events/qrcode/{qrId}/deactivate`
- `POST /api/attendance/checkin`
- `POST /api/attendance/checkin/requirements`
- `GET /api/attendance/my-history`
- `GET /api/attendance/check-status/{eventId}`
- `GET /api/users/me/points`
- `GET /api/users/me/points/history`
- `GET /api/notifications`
- `GET /api/notifications/unread-count`
- `PUT /api/notifications/{id}/read`
- `PUT /api/notifications/read-all`
- `POST /api/device-tokens`
- `DELETE /api/device-tokens`
- `GET /api/support-chat/conversations/my`
- `GET /api/support-chat/conversations`
- `POST /api/support-chat/conversations`
- `GET /api/support-chat/conversations/{conversationId}/messages`
- `POST /api/support-chat/conversations/{conversationId}/messages`
- `POST /api/support-chat/conversations/{conversationId}/attachments`
- `GET /api/events/{eventId}/attendance-stats`
- `GET /api/events/{eventId}/attendances`
- `GET /api/events/all/attendance-stats`
- `GET /api/events/notification-observability`
- `GET /api/events/biometric-telemetry`

SignalR hubs:

```text
/hubs/notifications
/hubs/support-chat
```

Endpoint nội bộ của face-service:

```text
POST /internal/face/verify
POST /internal/face/enroll
POST /internal/face/liveness/check
```

## Authentication

Backend API:

- Dùng JWT Bearer authentication.
- Bắt buộc cấu hình `Jwt__Key`, `Jwt__Issuer`, `Jwt__Audience`.
- SignalR hubs có thể nhận token từ query string `access_token`.
- Phân quyền theo role `Admin`, `CanBo`, `DoanVien`, `HoiVien`.
- Refresh token được lưu trong SQL Server.
- Endpoint nhạy cảm có ASP.NET Core rate limiting.

Web Admin:

- Lưu JWT trong HttpOnly cookie `UniYouthAuth`.
- Dùng global `AdminAuthorizeFilter`.
- Cho phép workflow admin/cán bộ dựa trên JWT claims đã validate.
- `JwtSettings__SecretKey` phải trùng với backend `Jwt__Key`.

Mobile App:

- Lưu auth session bằng `flutter_secure_storage`.
- Dùng Dio interceptors để gắn token và refresh session.
- Tự xử lý cleanup session và điều hướng về login khi unauthorized.

## Testing

Kiểm thử backend:

```bash
cd backend-api
dotnet test
```

Kiểm tra build Web Admin:

```bash
cd web-admin
dotnet build
```

Kiểm thử mobile:

```bash
cd mobile-app
flutter analyze
flutter test
```

Kiểm tra cú pháp face-service:

```bash
cd backend-api/services/face-service
python -m compileall app tools
```

## Docker

Cần cấu hình thủ công:

- Repo hiện không có Dockerfile.
- Repo hiện không có `docker-compose.yml`.
- Nếu deploy bằng Docker, cần thêm Dockerfile cho:
  - `backend-api/UniYouth.Api`
  - `web-admin/UniYouth.Admin`
  - `backend-api/services/face-service`
  - SQL Server container hoặc external SQL Server connection

Layout có thể bổ sung sau:

```text
docker-compose.yml
backend-api/UniYouth.Api/Dockerfile
web-admin/UniYouth.Admin/Dockerfile
backend-api/services/face-service/Dockerfile
```

## Deployment

Cần cấu hình thủ công:

- Provision SQL Server và chạy database scripts.
- Publish Backend API với đầy đủ environment variables.
- Publish Web Admin với `ApiSettings__BaseUrl` trỏ đến Backend API.
- Publish face-service trong internal network hoặc route được bảo vệ.
- Cấu hình HTTPS reverse proxy như IIS, Nginx, Caddy, Cloudflare Tunnel hoặc cloud load balancer.
- Cấu hình persistent storage cho `wwwroot/uploads`.
- Cấu hình Firebase/Gmail/SMTP credentials ngoài source control.
- Cấu hình `API_BASE_URL` cho bản build production của mobile.

Flow deploy thủ công gợi ý:

```bash
dotnet publish backend-api/UniYouth.Api -c Release -o publish/api
dotnet publish web-admin/UniYouth.Admin -c Release -o publish/admin
```

Sau đó host:

- API tại `https://api.example.com`
- Admin tại `https://admin.example.com`
- Face-service tại URL nội bộ, ví dụ `http://127.0.0.1:8001`
- SQL Server trong private network

## Troubleshooting

### Backend reports `ConnectionStrings:UniYouth is not configured`

Nguyên nhân: backend bắt buộc có `ConnectionStrings__UniYouth`.

Cách xử lý:

```powershell
$env:ConnectionStrings__UniYouth = 'Data Source=localhost;Initial Catalog=UniYouth;Integrated Security=True;Trust Server Certificate=True'
```

### Backend reports `JWT Key is not configured`

Nguyên nhân: backend bắt buộc có `Jwt__Key`.

Cách xử lý:

```powershell
$env:Jwt__Key = 'REPLACE_WITH_A_LONG_RANDOM_SECRET_AT_LEAST_32_CHARS'
```

### Admin login succeeds but redirects to login or unauthorized

Nguyên nhân có thể là:

- `JwtSettings__SecretKey` trong Admin không trùng backend `Jwt__Key`.
- Backend `Jwt__Issuer` / `Jwt__Audience` khác Admin `JwtSettings`.
- Cookie settings không phù hợp môi trường HTTP/HTTPS.

### Admin cannot call Backend API

Nguyên nhân: `ApiSettings__BaseUrl` trống hoặc sai URL.

Cách xử lý:

```powershell
$env:ApiSettings__BaseUrl = 'http://localhost:5160'
```

### Mobile cannot connect to API

Nguyên nhân có thể là:

- Backend chưa chạy ở port `5160`.
- Android emulator không truy cập được host `localhost`.
- `APP_ENV=prod` đang dùng loopback URL, app sẽ từ chối.

Ví dụ xử lý:

```bash
flutter run --dart-define=APP_ENV=dev --dart-define=API_BASE_URL=http://10.0.2.2:5160
flutter run --dart-define=APP_ENV=dev --dart-define=API_BASE_URL=http://192.168.1.12:5160
```

### Face verification fails

Nguyên nhân có thể là:

- Face-service chưa chạy.
- Chưa set `FaceVerification__Service__BaseUrl`.
- Chưa cài Python dependencies.
- DeepFace model warmup thất bại.

Cách xử lý:

```bash
cd backend-api/services/face-service
python -m uvicorn app.main:app --host 127.0.0.1 --port 8001
```

Sau đó set:

```powershell
$env:FaceVerification__Service__BaseUrl = 'http://127.0.0.1:8001'
```

### Database script deletes existing database

`DatabaseScripts/UniYouth.sql` drop database `[UniYouth]` nếu database này đã tồn tại. Hãy đọc kỹ script trước khi chạy trên máy có dữ liệu thật.

### Port already in use

Port mặc định:

- Backend API: `5160`, `7016`
- Web Admin: `5036`, `7091`
- Face-service: `8001`

Dừng process đang dùng port hoặc đổi launch profile/application URL.

### Build fails after clone

Kiểm tra:

- Đã cài .NET SDK 8.
- Flutter SDK hỗ trợ Dart `^3.10.7`.
- Python version là 3.11+.
- Đã chạy restore trước khi build/test.
- Runtime secrets không cần cho restore, nhưng cần khi chạy backend/admin.

## Contributing

- Làm việc từ monorepo root trừ khi task yêu cầu rõ repo riêng.
- Không commit secret vào source control.
- Không commit thư mục generated như `bin/`, `obj/`, `.vs/`, `.dart_tool/`, `build/`, `.venv/`, `.python/`.
- Chạy các kiểm tra liên quan trước khi gửi thay đổi:

```bash
cd backend-api && dotnet test
cd ../web-admin && dotnet build
cd ../mobile-app && flutter analyze && flutter test
```

- Đồng bộ thay đổi API DTO giữa backend, web admin và mobile client.
- Cập nhật README khi setup, config, endpoint hoặc deployment requirements thay đổi.

## Maintainer

**Trinh Dao**

- GitHub: https://github.com/diemtrinh05
- Email: diemtrinhdao05@gmail.com

Nếu có câu hỏi kỹ thuật, vui lòng tạo Issue trước.

## License

Cần cấu hình thủ công.

Repo hiện chưa có file `LICENSE`. Nếu dự án dùng MIT License, hãy thêm file `LICENSE` ở root repo với nội dung MIT License.

## Documentation Status

Mức độ hoàn thiện ước tính: **82%**

Đã bao phủ:

- Ngôn ngữ, framework và package thực tế trong source.
- Cấu trúc monorepo.
- Setup Backend, Admin, Mobile và Face-service.
- Các key cấu hình runtime từ `appsettings.json`, Dart config và `.env.example`.
- Thiết lập database dựa trên SQL Server scripts.
- Các nhóm endpoint chính từ controllers.
- Mô hình xác thực của backend, admin và mobile.
- Lệnh build/test.
- Các thiếu sót Docker/deployment đã được đánh dấu là cần cấu hình thủ công.

Còn thiếu / cần project owner bổ sung:

- Script database chuẩn để khởi tạo môi trường và tài khoản seed.
- Domain production và topology triển khai.
- Firebase project files và push notification credentials.
- SMTP/Gmail credentials và email provider chính thức.
- Google Maps API key.
- Quyết định giấy phép chính thức và file `LICENSE`.
- Dockerfile/docker-compose nếu cần container deployment.
- Mô hình hosting face-service cho production.

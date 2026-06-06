# UniYouth

## Overview

UniYouth là hệ thống quản lý hoạt động đoàn hội và điểm rèn luyện. Repo này là monorepo public, gồm backend API, web admin và mobile app. Hệ thống hỗ trợ quản lý sự kiện, đăng ký tham gia, điểm hoạt động, điểm danh bằng QR/GPS/khuôn mặt, thông báo, hỗ trợ người dùng và báo cáo quản trị.

Repo public này không chứa secret, file cấu hình runtime cá nhân, build output, cache, virtualenv, APK hoặc các file nằm trong `.gitignore`.

## Features

- Đăng nhập bằng tài khoản nội bộ, JWT access token và refresh token.
- Quên mật khẩu, OTP xác thực và đặt lại mật khẩu.
- Quản lý người dùng, hồ sơ cá nhân, avatar, vai trò và trạng thái tài khoản.
- Quản lý đơn vị, viện, chức vụ và phân quyền theo vai trò.
- Quản lý loại sự kiện, sự kiện, ảnh sự kiện, trạng thái sự kiện và địa điểm.
- Đăng ký và hủy đăng ký tham gia sự kiện.
- Sinh, xem chi tiết và vô hiệu hóa QR code điểm danh.
- Điểm danh sự kiện bằng QR code, GPS, device id, face verification và passive liveness.
- Quản lý điểm hoạt động và lịch sử điểm của người dùng.
- Báo cáo điểm danh, thống kê sự kiện, telemetry sinh trắc học và observability thông báo.
- Notification inbox, unread count, mark as read, mark all as read.
- Push notification qua FCM/APNS theo cấu hình runtime.
- Realtime notification và support chat qua SignalR.
- Web Admin cho cán bộ/admin: dashboard, sự kiện, QR, điểm danh, người dùng, báo cáo, notification, support chat.
- Mobile app cho người dùng: đăng nhập, sự kiện, đăng ký, điểm danh QR, lịch sử điểm danh, điểm, thông báo, hồ sơ, hỗ trợ.
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
- xUnit, Moq, EF Core InMemory for tests

### Web Admin

- C# / .NET 8
- ASP.NET Core MVC / Razor Views
- HttpClient-based API services
- JWT validation from HttpOnly cookie
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
- TensorFlow/Keras via `tf-keras`
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

Kiến trúc backend là monolithic layered architecture:

- `Controllers`: nhận HTTP request và trả API response.
- `Application/Services`: business logic.
- `Contracts/DTOs`: request/response DTO.
- `Domain/Entities`: entity ánh xạ database.
- `Infrastructure/Data`: EF Core DbContext và mapping.
- `Shared`: constants, enums, exception handling, helpers, idempotency, push notification, face verification options.

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
- PowerShell nếu dùng các script trong `backend-api/scripts`
- Firebase project/service account nếu bật FCM push notification
- SMTP hoặc Gmail API credentials nếu bật email
- Cloudflare Tunnel nếu dùng public tunnel script

## Installation

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

Create Python environment for face-service:

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

Runtime configuration is intentionally empty in public source. Use environment variables, user-secrets or local untracked files.

### Backend API

File:

```text
backend-api/UniYouth.Api/appsettings.json
```

Important configuration keys:

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

Minimal local PowerShell example:

```powershell
$env:ConnectionStrings__UniYouth = 'Data Source=localhost;Initial Catalog=UniYouth;Integrated Security=True;Trust Server Certificate=True'
$env:Jwt__Key = 'REPLACE_WITH_A_LONG_RANDOM_SECRET_AT_LEAST_32_CHARS'
$env:PublicBaseUrl = 'http://localhost:5160'
$env:PasswordReset__PublicResetBaseUrl = 'https://localhost:7091'
$env:FaceVerification__Service__BaseUrl = 'http://127.0.0.1:8001'
```

### Web Admin

File:

```text
web-admin/UniYouth.Admin/appsettings.json
```

Important configuration keys:

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

`JwtSettings__SecretKey` must match backend `Jwt__Key`.

### Mobile App

Mobile API config is resolved in:

```text
mobile-app/lib/services/config/api_config_service.dart
```

Supported dart defines:

```env
APP_ENV=dev|staging|prod
API_BASE_URL=
```

Rules found in source:

- Default `APP_ENV` is `dev`.
- Dev mode defaults to `http://localhost:5160`.
- Dev mode can save a LAN server IP inside the app.
- `staging` and `prod` require `API_BASE_URL`.
- Production build rejects loopback hosts such as `localhost`, `127.0.0.1`, `::1`, `10.0.2.2`.

Examples:

```bash
flutter run --dart-define=APP_ENV=dev --dart-define=API_BASE_URL=http://localhost:5160
flutter run --dart-define=APP_ENV=staging --dart-define=API_BASE_URL=https://api.example.com
flutter run --release --dart-define=APP_ENV=prod --dart-define=API_BASE_URL=https://api.example.com
```

Need Manual Configuration:

- Firebase platform files are not included in this public repo.
- Add the correct Firebase configuration files for Android/iOS if push notification is required.

### Face Service

File:

```text
backend-api/services/face-service/.env.example
```

Important environment variables:

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

The main scripts are in:

```text
backend-api/DatabaseScripts/
```

The public repo contains full SQL scripts such as:

- `UniYouth.sql`
- `UniYouth_v2.sql`
- `UniYouth_v3.sql`
- `UniYouth_v4.sql`
- dated incremental scripts under `DatabaseScripts/`

`UniYouth.sql` creates database `[UniYouth]` and drops an existing database with the same name before creating it. Review the script before running it on any machine with existing data.

Example using SQL Server tools:

```sql
CREATE DATABASE UniYouth;
```

Then run the schema/data script appropriate for your environment. The repo does not contain EF Core migration files, so database setup is script-based.

Need Manual Configuration:

- Choose which SQL script is the canonical seed for your environment.
- Verify initial admin/canbo/student accounts from the SQL script before first login.
- Configure `ConnectionStrings__UniYouth` to point to the created database.

## Running Project

### Development

Start face-service:

```bash
cd backend-api/services/face-service
python -m uvicorn app.main:app --host 127.0.0.1 --port 8001
```

Start backend API:

```bash
cd backend-api
dotnet run --project UniYouth.Api --launch-profile http
```

Default backend URLs from `launchSettings.json`:

```text
http://localhost:5160
https://localhost:7016
```

Start web admin:

```bash
cd web-admin
dotnet run --project UniYouth.Admin --launch-profile https
```

Default admin URLs from `launchSettings.json`:

```text
http://localhost:5036
https://localhost:7091
```

Start mobile app:

```bash
cd mobile-app
flutter run --dart-define=APP_ENV=dev --dart-define=API_BASE_URL=http://localhost:5160
```

Android emulator note:

- The source default uses `localhost` in dev mode.
- If the emulator cannot reach backend, use the in-app dev API config screen or pass a reachable host.
- For Android emulator, `10.0.2.2` usually points to host localhost.

### Optional PowerShell Stack Scripts

Scripts exist under:

```text
backend-api/scripts/
```

Relevant scripts:

- `face_stack.ps1`: starts/stops face-service, API and admin in the older separate-repo layout.
- `public_stack.ps1`: wraps local stack and Cloudflare tunnel.
- `dev-runtime-env.example.ps1`: example environment variables.
- `setup_cloudflare_tunnel.ps1`: Cloudflare tunnel setup helper.

Need Manual Configuration:

- These scripts were authored around a sibling admin repo layout. In this monorepo, set `UNIYOUTH_ADMIN_ROOT` to the absolute `web-admin` path if using the scripts.
- Copy `dev-runtime-env.example.ps1` to an untracked local secret file before adding real values.

### Production

Need Manual Configuration:

- No Dockerfile or `docker-compose.yml` exists in the current repo.
- Production hosting must be configured manually for the API, admin web app, SQL Server, face-service and public HTTPS routing.

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

Other Flutter targets are present in the repo (`android`, `ios`, `web`, `windows`, `linux`, `macos`), but platform-specific signing/build settings require manual setup.

Face-service syntax check:

```bash
cd backend-api/services/face-service
python -m compileall app tools
```

## API Documentation

Swagger is enabled only in Development and is mounted at the API root:

```text
http://localhost:5160/
http://localhost:5160/swagger/v1/swagger.json
```

Main endpoint groups found in controllers:

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

Face-service internal endpoints:

```text
POST /internal/face/verify
POST /internal/face/enroll
POST /internal/face/liveness/check
```

## Authentication

Backend API:

- Uses JWT Bearer authentication.
- `Jwt__Key`, `Jwt__Issuer`, `Jwt__Audience` are required.
- SignalR hubs can receive token from `access_token` query string.
- Role-based authorization is used for `Admin`, `CanBo`, `DoanVien`, `HoiVien`.
- Refresh tokens are persisted in SQL Server.
- Sensitive endpoints use ASP.NET Core rate limiting.

Web Admin:

- Stores JWT in HttpOnly cookie `UniYouthAuth`.
- Uses a global `AdminAuthorizeFilter`.
- Allows admin/canbo web workflows based on validated JWT claims.
- `JwtSettings__SecretKey` must match backend `Jwt__Key`.

Mobile App:

- Stores auth session using `flutter_secure_storage`.
- Uses Dio interceptors to attach tokens and refresh session.
- Handles unauthorized session cleanup and redirect to login.

## Testing

Backend tests:

```bash
cd backend-api
dotnet test
```

Web Admin build check:

```bash
cd web-admin
dotnet build
```

Mobile tests:

```bash
cd mobile-app
flutter analyze
flutter test
```

Face-service syntax check:

```bash
cd backend-api/services/face-service
python -m compileall app tools
```

## Docker

Need Manual Configuration:

- No Dockerfile exists in the current repo.
- No `docker-compose.yml` exists in the current repo.
- To deploy with Docker, add Dockerfiles for:
  - `backend-api/UniYouth.Api`
  - `web-admin/UniYouth.Admin`
  - `backend-api/services/face-service`
  - SQL Server container or external SQL Server connection

Example target layout to add later:

```text
docker-compose.yml
backend-api/UniYouth.Api/Dockerfile
web-admin/UniYouth.Admin/Dockerfile
backend-api/services/face-service/Dockerfile
```

## Deployment

Need Manual Configuration:

- Provision SQL Server and run database scripts.
- Publish backend API with required environment variables.
- Publish Web Admin with `ApiSettings__BaseUrl` pointing to backend API.
- Publish face-service behind internal network or protected route.
- Configure HTTPS reverse proxy such as IIS, Nginx, Caddy, Cloudflare Tunnel or a cloud load balancer.
- Configure persistent storage for `wwwroot/uploads`.
- Configure Firebase/Gmail/SMTP credentials outside source control.
- Configure mobile app `API_BASE_URL` for production builds.

Suggested manual deployment flow:

```bash
dotnet publish backend-api/UniYouth.Api -c Release -o publish/api
dotnet publish web-admin/UniYouth.Admin -c Release -o publish/admin
```

Then host:

- API on `https://api.example.com`
- Admin on `https://admin.example.com`
- Face-service on an internal URL, for example `http://127.0.0.1:8001`
- SQL Server on a private network

## Troubleshooting

### Backend fails with `ConnectionStrings:UniYouth is not configured`

Cause: backend requires `ConnectionStrings__UniYouth`.

Fix:

```powershell
$env:ConnectionStrings__UniYouth = 'Data Source=localhost;Initial Catalog=UniYouth;Integrated Security=True;Trust Server Certificate=True'
```

### Backend fails with `JWT Key is not configured`

Cause: backend requires `Jwt__Key`.

Fix:

```powershell
$env:Jwt__Key = 'REPLACE_WITH_A_LONG_RANDOM_SECRET_AT_LEAST_32_CHARS'
```

### Admin login works but pages redirect to login or unauthorized

Possible causes:

- `JwtSettings__SecretKey` in Admin does not match backend `Jwt__Key`.
- Backend `Jwt__Issuer` / `Jwt__Audience` differs from Admin `JwtSettings`.
- Cookie settings are incompatible with HTTP/HTTPS environment.

### Admin cannot call backend API

Cause: `ApiSettings__BaseUrl` is empty or points to the wrong URL.

Fix:

```powershell
$env:ApiSettings__BaseUrl = 'http://localhost:5160'
```

### Mobile cannot connect to API

Possible causes:

- Backend is not running on port `5160`.
- Android emulator cannot reach host `localhost`.
- `APP_ENV=prod` is using a loopback URL, which the app rejects.

Fix examples:

```bash
flutter run --dart-define=APP_ENV=dev --dart-define=API_BASE_URL=http://10.0.2.2:5160
flutter run --dart-define=APP_ENV=dev --dart-define=API_BASE_URL=http://192.168.1.12:5160
```

### Face verification fails

Possible causes:

- Face-service is not running.
- `FaceVerification__Service__BaseUrl` is not set.
- Python dependencies are not installed.
- DeepFace model warmup failed.

Fix:

```bash
cd backend-api/services/face-service
python -m uvicorn app.main:app --host 127.0.0.1 --port 8001
```

Then set:

```powershell
$env:FaceVerification__Service__BaseUrl = 'http://127.0.0.1:8001'
```

### Database script deletes existing database

`DatabaseScripts/UniYouth.sql` drops existing `[UniYouth]` before creating it. Review scripts before running them on any machine with existing data.

### Port already in use

Default ports:

- Backend API: `5160`, `7016`
- Web Admin: `5036`, `7091`
- Face-service: `8001`

Stop the existing process or change launch profile/application URL.

### Build failed after clone

Check:

- .NET SDK 8 is installed.
- Flutter SDK supports Dart `^3.10.7`.
- Python version is 3.11+.
- Run restore commands before build/test.
- Runtime secrets are not required for restore, but are required for running backend/admin.

## Contributing

- Work from the monorepo root unless a task explicitly targets a separate private repo.
- Keep secrets out of source control.
- Do not commit generated folders such as `bin/`, `obj/`, `.vs/`, `.dart_tool/`, `build/`, `.venv/`, `.python/`.
- Run relevant checks before submitting changes:

```bash
cd backend-api && dotnet test
cd ../web-admin && dotnet build
cd ../mobile-app && flutter analyze && flutter test
```

- Keep API DTO changes synchronized between backend, web admin and mobile clients.
- Update this README when setup, config, endpoints or deployment requirements change.

## Maintainer

**Trinh Dao**

- GitHub: https://github.com/diemtrinh05
- Email: diemtrinhdao05@gmail.com

For technical questions, please open an Issue first.

## License

Need Manual Configuration.

No `LICENSE` file is present in the current repo. If the project is intended to use MIT License, add a root `LICENSE` file containing the MIT license text.

## Documentation Status

Estimated completeness: **82%**

Covered:

- Actual languages, frameworks and packages found in source.
- Monorepo structure.
- Backend, Admin, Mobile and Face-service setup.
- Runtime configuration keys found in `appsettings.json`, Dart config and `.env.example`.
- SQL Server script-based database setup.
- Main API endpoint groups from controllers.
- Authentication model for backend, admin and mobile.
- Build/test commands.
- Docker/deployment gaps marked as `Need Manual Configuration`.

Still missing / needs project owner input:

- Canonical database initialization script and seed account credentials.
- Production domain names and deployment topology.
- Firebase project files and push notification credentials.
- SMTP/Gmail credentials and preferred email provider.
- Google Maps API key.
- Official license decision and `LICENSE` file.
- Dockerfiles/docker-compose if container deployment is required.
- Exact face-service hosting model for production.

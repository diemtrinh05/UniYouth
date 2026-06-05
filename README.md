# UniYouth

UniYouth là hệ thống quản lý hoạt động đoàn hội và điểm rèn luyện, gồm 3 phần chính:

- `backend-api/`: ASP.NET Core Web API, cơ sở dữ liệu, notification, SignalR, background jobs và face-service Python.
- `web-admin/`: ASP.NET Core MVC/Razor Web Admin cho quản trị viên.
- `mobile-app/`: Flutter mobile app cho người dùng.

Repo public này chỉ chứa source code cần thiết để tham khảo và chạy dev. Các file local/ignored như `bin/`, `obj/`, `.vs/`, `.dart_tool/`, `build/`, `secrets/`, virtualenv Python, APK và cache không được đưa lên repo này.

## Yêu Cầu

- .NET SDK 8
- SQL Server
- Flutter SDK
- Android Studio hoặc Android SDK nếu chạy mobile Android
- Python 3.11+ nếu chạy face-service
- Git

## Cấu Trúc

```text
UniYouth/
  backend-api/
    UniYouth.Api.sln
    UniYouth.Api/
    UniYouth.Api.Tests/
    DatabaseScripts/
    services/face-service/
  web-admin/
    UniYouth.Admin.sln
    UniYouth.Admin/
  mobile-app/
    pubspec.yaml
    lib/
    android/
    ios/
```

## Backend API

```powershell
cd backend-api
dotnet restore
dotnet build
dotnet test
dotnet run --project UniYouth.Api
```

Backend cần cấu hình runtime riêng cho dev, ví dụ:

- SQL Server connection string
- JWT settings
- SMTP/Gmail settings
- Firebase/FCM settings nếu dùng push notification
- Public URL / Cloudflare tunnel nếu dùng callback hoặc asset URL public
- Face-service URL nếu dùng xác thực khuôn mặt

Không commit secret thật lên repo public. Hãy tạo file config local hoặc dùng environment variables trên máy dev.

## Web Admin

```powershell
cd web-admin
dotnet restore
dotnet build
dotnet run --project UniYouth.Admin
```

Web Admin gọi API từ backend. Cần cấu hình `ApiBaseUrl` trỏ đến URL backend đang chạy trên máy dev.

## Mobile App

```powershell
cd mobile-app
flutter pub get
flutter analyze
flutter test
flutter run
```

Mobile app cần cấu hình API base URL phù hợp với môi trường chạy:

- Android emulator thường dùng `10.0.2.2` để trỏ về localhost của máy host.
- Thiết bị thật cần dùng IP LAN hoặc public URL của backend.

Nếu dùng Firebase/FCM, cần bổ sung file cấu hình Firebase local theo từng platform.

## Face Service

```powershell
cd backend-api/services/face-service
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
python -m compileall .
```

Chạy service theo entrypoint/thiết lập hiện có trong thư mục `services/face-service/`. Thư mục virtualenv local không được commit trong repo public.

## Database

Database scripts nằm trong:

```text
backend-api/DatabaseScripts/
```

Chạy các script phù hợp với database dev của bạn trước khi start backend. Kiểm tra connection string local trước khi chạy migration/script.

## Ghi Chú Bảo Mật

Repo này là public nên không chứa:

- Mật khẩu database
- JWT secret
- SMTP password
- Firebase service account
- Cloudflare tunnel credentials
- File `secrets/`
- Build output và cache local

Nếu clone repo này để chạy dev, hãy tạo cấu hình runtime riêng trên máy local.

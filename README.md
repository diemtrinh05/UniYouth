# UniYouth

UniYouth la he thong quan ly hoat dong doan hoi va diem ren luyen, gom 3 phan chinh:

- `backend-api/`: ASP.NET Core Web API, database, notification, SignalR, background jobs va face-service Python.
- `web-admin/`: ASP.NET Core MVC/Razor Web Admin cho quan tri vien.
- `mobile-app/`: Flutter mobile app cho nguoi dung.

Repo public nay chi chua source code can thiet de tham khao va chay dev. Cac file local/ignored nhu `bin/`, `obj/`, `.vs/`, `.dart_tool/`, `build/`, `secrets/`, virtualenv Python, APK va cache khong duoc dua len repo nay.

## Prerequisites

- .NET SDK 8
- SQL Server
- Flutter SDK
- Android Studio hoac Android SDK neu chay mobile Android
- Python 3.11+ neu chay face-service
- Git

## Cau truc

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

Backend can cau hinh runtime rieng cho dev, vi du:

- SQL Server connection string
- JWT settings
- SMTP/Gmail settings
- Firebase/FCM settings neu dung push notification
- Public URL / Cloudflare tunnel neu dung callback hoac asset URL public
- Face-service URL neu dung xac thuc khuon mat

Khong commit secret that len repo public. Tao file config local hoac dung environment variables tren may dev.

## Web Admin

```powershell
cd web-admin
dotnet restore
dotnet build
dotnet run --project UniYouth.Admin
```

Web Admin goi API tu backend. Can cau hinh `ApiBaseUrl` tro den URL backend dang chay tren may dev.

## Mobile App

```powershell
cd mobile-app
flutter pub get
flutter analyze
flutter test
flutter run
```

Mobile app can cau hinh API base URL phu hop voi moi truong chay:

- Android emulator thuong dung `10.0.2.2` de tro ve localhost cua may host.
- Thiet bi that can dung IP LAN hoac public URL cua backend.

Neu dung Firebase/FCM, can bo sung file cau hinh Firebase local theo tung platform.

## Face Service

```powershell
cd backend-api/services/face-service
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
python -m compileall .
```

Chay service theo entrypoint/thiet lap hien co trong thu muc `services/face-service/`. Thu muc virtualenv local khong duoc commit trong repo public.

## Database

Database scripts nam trong:

```text
backend-api/DatabaseScripts/
```

Chay cac script phu hop voi database dev cua ban truoc khi start backend. Kiem tra connection string local truoc khi chay migration/script.

## Ghi chu bao mat

Repo nay la public nen khong chua:

- Mat khau database
- JWT secret
- SMTP password
- Firebase service account
- Cloudflare tunnel credentials
- File `secrets/`
- Build output va cache local

Neu clone repo nay de chay dev, hay tao cau hinh runtime rieng tren may local.

# FLUTTER NOTIFICATION QA CHECKLIST

## 1. Mục tiêu
- Xác nhận notification flow hoạt động ổn định trên Mobile Flutter trước release.
- Dùng checklist này làm QA gate cho các task notification.

## 2. Phạm vi
- In-app notification list + unread badge.
- Mark-as-read (1 item và mark-all).
- Push handling ở 3 trạng thái app:
  - Foreground
  - Background
  - Terminated
- Deep link navigation từ push vào `Event Detail` hoặc fallback `Notification Screen`.
- State synchronization sau resume/open app.

## 3. API contract liên quan (theo swagger_v4.json)
- `GET /api/notifications`
- `GET /api/notifications/unread-count`
- `PUT /api/notifications/{id}/read`
- `PUT /api/notifications/read-all`
- `POST /api/device-tokens`
- `DELETE /api/device-tokens`

## 4. Tiền điều kiện
- Build Flutter đang trỏ đúng môi trường backend test.
- Đã cấu hình Firebase cho Android/iOS.
- Tài khoản test hợp lệ, đã đăng nhập.
- Có data thông báo test:
  - Ít nhất 1 thông báo unread có `eventId` hợp lệ.
  - Ít nhất 1 thông báo không có `eventId` để test fallback.
  - Ít nhất 1 thông báo đã đọc.
- Thiết bị có kết nối mạng ổn định, và có thể bật/tắt mạng để test network fail.

## 5. Hướng dẫn test trên giao diện
- Đăng nhập bằng tài khoản test đã có dữ liệu thông báo.
- Từ `Home`, nhấn icon chuông để mở `Notification Screen`.
- Kiểm tra trạng thái giao diện cơ bản trên màn hình thông báo:
  - Loading khi vừa mở màn hình.
  - Empty khi không có dữ liệu.
  - Error khi tắt mạng.
- Kéo xuống để test `pull-to-refresh`; kéo tới cuối danh sách để test `load more`.
- Nhấn `Đã đọc` trên từng item để test mark 1; nhấn `Đọc tất cả` để test mark all.
- Sau mỗi thao tác mark read, quay lại `Home` và đối chiếu badge unread.
- Kiểm thử push theo từng trạng thái app:
  - Foreground: giữ app đang mở, gửi push test.
  - Background: đưa app xuống nền, gửi push và tap notification.
  - Terminated: tắt hẳn app, gửi push và tap notification để cold start.
- Kiểm tra điều hướng từ push:
  - Có `eventId` hợp lệ -> vào `Event Detail`.
  - Payload thiếu/sai dữ liệu -> fallback an toàn về `Notification Screen`.
- Kiểm tra auth guard: session hết hạn thì tap push phải về `Login`.
- Kiểm tra sync khi resume: đưa app xuống nền rồi quay lại, unread và danh sách phải được đồng bộ.

## 6. Checklist chi tiết

| ID | Nhóm | Test case | Bước test | Kết quả mong đợi | Pass/Fail |
|---|---|---|---|---|---|
| NTF-QA-001 | Notification Screen | Tải danh sách thông báo | Mở Notification screen | Hiện loading -> data/empty/error state đúng, không crash | Pass nếu UI đúng trạng thái |
| NTF-QA-002 | Notification Screen | Phân trang | Scroll xuống cuối list để load more | Dữ liệu trang tiếp theo được thêm, không duplicate `notificationId` | Pass nếu không trùng item |
| NTF-QA-003 | Mark-As-Read | Mark 1 thông báo unread | Bấm "Đã đọc" trên 1 item unread | Gọi `PUT /notifications/{id}/read` thành công, item chuyển read | Pass nếu item update đúng |
| NTF-QA-004 | Mark-As-Read | Mark all | Bấm "Đọc tất cả" | Gọi `PUT /notifications/read-all`, unread giảm về 0 theo backend | Pass nếu unread đồng bộ |
| NTF-QA-005 | Badge | Đồng bộ badge Home + Notification | Sau mark read/all, quay về Home và vào lại Notification | Badge icon và unread count trên Notification đồng bộ cùng một giá trị | Pass nếu không lệch số |
| NTF-QA-006 | Foreground Push | Nhận push khi app đang mở | Để app foreground, gửi push test | Hiện local notification/in-app UX; app không crash khi payload thiếu field | Pass nếu không crash |
| NTF-QA-007 | Foreground Push | Cập nhật state sau push | Nhận push foreground -> mở Notification list | List được cập nhật và dedupe theo `notificationId`; unread cập nhật đúng | Pass nếu state đúng |
| NTF-QA-008 | Background Push | Tap push khi app background | Đẩy app về background, gửi push, tap notification | App mở đúng route mục tiêu (event detail/notifications) sau auth guard | Pass nếu route đúng |
| NTF-QA-009 | Terminated Push | Tap push khi app đã tắt | Tắt hẳn app, gửi push, tap notification | App cold start và điều hướng đúng, không crash | Pass nếu route đúng |
| NTF-QA-010 | Deep Link Safety | Payload không hợp lệ | Gửi push payload sai/missing `eventId` | Không crash; fallback an toàn về Notification screen | Pass nếu fallback đúng |
| NTF-QA-011 | Auth Guard | Push khi session hết hạn | Session local không hợp lệ, tap push | App điều hướng Login, không vào protected route | Pass nếu guard đúng |
| NTF-QA-012 | State Sync | Resume app để sync | Mở app -> background -> resume | Trigger sync unread + first page theo policy, không stale state | Pass nếu dữ liệu mới |
| NTF-QA-013 | Network Error UX | Mất mạng khi load notifications | Tắt mạng, mở Notification screen | Hiện thông báo lỗi network thống nhất UX, không crash | Pass nếu message đúng |
| NTF-QA-014 | Token Lifecycle | Register token khi login/session restore | Đăng nhập mới hoặc mở lại app có session | Token sync flow chạy, không expose token trên UI/log | Pass nếu không lỗi flow |
| NTF-QA-015 | Security Logging | Sanitize payload log | Test payload có key nhạy cảm (token/password) ở debug | Log chỉ hiện summary đã redacted, không log raw payload đầy đủ | Pass nếu không lộ dữ liệu |

## 7. Regression nhanh sau fix
- Chạy lại tối thiểu các case:
  - `NTF-QA-003`, `NTF-QA-004`, `NTF-QA-005`
  - `NTF-QA-008`, `NTF-QA-009`, `NTF-QA-010`
  - `NTF-QA-013`, `NTF-QA-015`

## 8. Tiêu chí GO/NO-GO
- GO khi:
  - Tất cả case P0 trong checklist PASS.
  - Không có crash trong 3 trạng thái push.
  - Không có lệch unread badge giữa Home và Notification screen.
  - Không phát hiện log payload nhạy cảm.
- NO-GO khi:
  - Bất kỳ case điều hướng sai hoặc crash fail.
  - Mark-as-read không đồng bộ unread count.
  - Có duplicate thông báo theo `notificationId`.

## 9. Mẫu ghi nhận kết quả
| Ngày test | Người test | Build | Device/OS | Tổng case | Pass | Fail | Kết luận |
|---|---|---|---|---:|---:|---:|---|
| yyyy-mm-dd |  |  |  |  |  |  | GO/NO-GO |

## 10. Automation smoke script
### 10.1 Bộ test tự động cho notification regressions
- `test/core/notifications/notification_navigation_handler_test.dart`
- `test/core/notifications/notification_payload_log_sanitizer_test.dart`
- `test/presentation/shared/mappers/notification_error_ui_mapper_test.dart`

### 10.2 Lệnh chạy nhanh (local)
```bash
flutter test test/core/notifications/notification_navigation_handler_test.dart
flutter test test/core/notifications/notification_payload_log_sanitizer_test.dart
flutter test test/presentation/shared/mappers/notification_error_ui_mapper_test.dart
```

### 10.3 Lệnh smoke gộp trước khi merge
```bash
flutter test \
  test/core/notifications/notification_navigation_handler_test.dart \
  test/core/notifications/notification_payload_log_sanitizer_test.dart \
  test/presentation/shared/mappers/notification_error_ui_mapper_test.dart
```

### 10.4 Quy ước đánh giá smoke
- PASS khi tất cả test trên đều xanh và không có test flaky.
- FAIL khi bất kỳ test nào đỏ hoặc test không chạy được do regression.
- Khi FAIL phải đính kèm:
  - Tên test fail
  - Commit hash
  - Ảnh hưởng tới nhóm case nào trong bảng `NTF-QA-001 ... NTF-QA-015`

## 11. Mapping test tự động ↔ checklist tay
| Test file tự động | Nhóm checklist liên quan | Mục tiêu regression |
|---|---|---|
| `notification_navigation_handler_test.dart` | `NTF-QA-008`, `NTF-QA-009`, `NTF-QA-010`, `NTF-QA-011` | Deep link resolve + fallback + auth-safe route intent |
| `notification_payload_log_sanitizer_test.dart` | `NTF-QA-015` | Không lộ dữ liệu nhạy cảm trong log payload/actionUrl |
| `notification_error_ui_mapper_test.dart` | `NTF-QA-013` | Message integrity/fallback ổn định cho notification UX |


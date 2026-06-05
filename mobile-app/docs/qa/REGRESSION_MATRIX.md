# REGRESSION MATRIX

## 1. Mục đích
- Chuẩn hóa phạm vi regression cho các luồng nghiệp vụ chính của app Flutter.
- Dùng để quyết định mức test cần chạy theo mức độ thay đổi trước mỗi release.

## 2. Phân loại mức regression
- `SMOKE`: chạy nhanh để xác nhận build dùng được.
- `P0`: luồng sống còn, fail là chặn release.
- `P1`: luồng quan trọng, có thể chặn release theo mức độ ảnh hưởng.
- `P2`: luồng bổ trợ.

## 3. Ma trận regression theo luồng nghiệp vụ
| Flow | Mức | API chính | Case bắt buộc | Điều kiện PASS | Điều kiện FAIL |
|---|---|---|---|---|---|
| Auth login/session | P0 | `POST /api/Auth/login` | Đăng nhập đúng/sai, token hết hạn, 429 | Đăng nhập đúng vào Home, sai thì báo lỗi chuẩn, 401 quay về login | Không vào được app, hoặc session sai trạng thái |
| Event list/filter/pagination | P0 | `GET /api/Events` | Tải list, filter, load-more, refresh | Hiển thị đúng dữ liệu, không đứng màn hình | Treo màn, stale-state, lỗi đỏ runtime |
| Event detail | P0 | `GET /api/Events/{id}` | Mở chi tiết từ list/notification | Detail hiển thị đúng event, không lỗi id | Lỗi `eventId` không hợp lệ, crash khi back |
| Register event | P0 | `POST /api/events/{eventId}/register` | Đăng ký hợp lệ, double tap, quá hạn | Trạng thái đồng bộ list/detail, không duplicate | Đăng ký lặp, trạng thái sai sau thao tác |
| Cancel registration | P0 | `DELETE /api/events/{eventId}/register` | Hủy đăng ký và đồng bộ lại màn hình | Trạng thái trở về chưa đăng ký đúng backend | Hủy xong UI không đồng bộ |
| Attendance check-in | P0 | `POST /api/attendance/checkin` | Hợp lệ, QR hết hạn, quá xa, đã check-in, 429 | Hiển thị kết quả đúng theo backend (`isValid`/status code) | Báo thành công sai, hoặc sai edge-case |
| Points summary | P1 | `GET /api/users/me/points` | Mở màn tổng quan, refresh sau check-in | Điểm hiển thị đúng dữ liệu backend | Sai tổng điểm/chỉ số hoặc stale |
| Notifications list | P1 | `GET /api/notifications` | Tải list + badge unread | List và badge hiển thị đúng | Badge sai, dữ liệu không đồng bộ |
| Mark as read | P1 | `PUT /api/notifications/{id}/read` | Đánh dấu đã đọc từng item | Unread giảm đúng, item cập nhật đúng | Đánh dấu đọc nhưng badge không đổi |

## 4. Regression theo loại thay đổi
| Loại thay đổi | Mức regression tối thiểu | Phạm vi chạy |
|---|---|---|
| Chỉ đổi UI tĩnh (không động tới state/network) | SMOKE + P1 liên quan | Login mở app, event list mở trang, notification mở trang |
| Đổi networking/interceptor/error handling | P0 full + P1 full | Toàn bộ flow trong bảng mục 3 |
| Đổi logic auth/session | P0 full | Auth + event + attendance + notifications |
| Đổi event/registration | P0 full (event + registration + notification) | Event list/detail + register/cancel + mark read |
| Đổi attendance | P0 full (attendance edge cases) + P1 points | Check-in edge + points summary + history liên quan |

## 5. Release gate
- `GO` khi:
  - 100% case `P0` PASS.
  - Không có lỗi crash/hang UI ở luồng chính.
  - Các lỗi `P1` (nếu có) đã được đánh giá rủi ro và có quyết định rõ.
- `NO-GO` khi:
  - Có ít nhất 1 case `P0` FAIL.
  - Có bug khiến user không thể hoàn thành login/register/check-in.

## 6. Mẫu log regression run
| Build | Ngày | Người chạy | Scope | P0 Pass/Total | P1 Pass/Total | Kết luận |
|---|---|---|---|---:|---:|---|
|  | yyyy-mm-dd |  | SMOKE/P0/P1 |  |  | GO/NO-GO |


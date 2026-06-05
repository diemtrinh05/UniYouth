# WEB CHROME CORS REGISTER ISSUE

## 7. Lỗi backend cần kiểm tra (Web Chrome)
- Mô tả lỗi:
  - Khi bấm `Đăng ký sự kiện` trên Web, Network chỉ có preflight `OPTIONS /api/events/{eventId}/register`.
  - Không phát sinh request `POST /api/events/{eventId}/register`.
- Hiện tượng quan sát:
  - Console/Network báo lỗi liên quan CORS.
  - `GET /api/events/{eventId}/my-registration` trả `404` chỉ thể hiện trạng thái chưa đăng ký, không phải lỗi chính của thao tác đăng ký.
- Nhận định nguyên nhân:
  - Backend chưa cho phép CORS header `Idempotency-Key` (hoặc thiếu allow header/method cần thiết), nên browser chặn request POST sau bước preflight.
- Backend cần kiểm tra và khắc phục:
  - CORS policy cho đúng origin frontend (ví dụ `http://localhost:<port>`).
  - `Access-Control-Allow-Headers` cần có tối thiểu:
    - `Authorization`
    - `Content-Type`
    - `Idempotency-Key`
  - `Access-Control-Allow-Methods` cần có tối thiểu:
    - `GET`, `POST`, `PUT`, `DELETE`, `OPTIONS`
  - Đảm bảo endpoint `POST /api/events/{eventId}/register` trả preflight hợp lệ trước khi xử lý POST thực tế.
- Kết quả mong đợi sau fix:
  - Sau preflight `OPTIONS` thành công, browser gửi tiếp `POST /api/events/{eventId}/register`.
  - Frontend nhận response đăng ký và cập nhật trạng thái bình thường.

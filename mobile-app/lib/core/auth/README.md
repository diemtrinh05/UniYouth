# Auth Session Hardening (TASK-32)

## Phạm vi hiện tại
- Backend hiện tại chỉ có `POST /api/Auth/login` để cấp token.
- Không có endpoint refresh token trong `swagger_v3.json`.
- Không có endpoint revoke/logout token phía server trong `swagger_v3.json`.

## Chiến lược client
- Mọi request có token sẽ được interceptor gắn header `Authorization`.
- Khi nhận `401`, app:
  - Xóa session local (`token`, `expiresAt`) và clear token trong memory.
  - Điều hướng về màn hình `Login` và reset navigation stack.
- Có cơ chế dedupe 401 trong một cửa sổ ngắn để tránh redirect lặp khi nhiều request cùng fail.

## Giới hạn kỹ thuật do thiếu API backend
- Không thể tự động làm mới token (refresh) khi token hết hạn.
- Không thể revoke token trên server khi logout local.
- Vì vậy, hành vi hiện tại là "fail-fast": nhận `401` thì xóa session local và bắt buộc đăng nhập lại.

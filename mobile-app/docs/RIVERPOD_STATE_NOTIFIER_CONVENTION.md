# Riverpod State Notifier Convention

## 1. Mục tiêu
- Chuẩn hóa cách tổ chức `State`/`Notifier`/`Provider` trong tầng `presentation`.
- Đảm bảo migrate sang Riverpod nhất quán giữa các module.
- Giữ nguyên business logic hiện có: chỉ thay vị trí quản lý state và binding UI.

## 2. Phạm vi áp dụng
- Áp dụng cho toàn bộ module trong `lib/presentation/features/*`.
- Ưu tiên các module có state phức tạp dùng `StateNotifierProvider`.
- Không thay đổi contract của `domain usecase` và `data repository`.

## 3. Cấu trúc thư mục chuẩn
- Mỗi feature có thư mục `state/` riêng.
- Trong `state/` dùng naming thống nhất:
  - `{feature}_state.dart`
  - `{feature}_notifier.dart`
  - `{feature}_provider.dart`

Ví dụ:
- `lib/presentation/features/auth/state/auth_state.dart`
- `lib/presentation/features/auth/state/auth_notifier.dart`
- `lib/presentation/features/auth/state/auth_provider.dart`

## 4. Quy ước State (immutable)
- `State` phải immutable, dùng `const` constructor.
- Mọi field của state là `final`.
- Có `copyWith()` để tạo state mới; không mutate trực tiếp.
- Tách rõ trạng thái tải dữ liệu:
  - `isInitialLoading`
  - `isRefreshing`
  - `isLoadingMore`
- Trường lỗi UI:
  - Dùng `errorMessage` hoặc `AppErrorUi` (nếu đã có mapper).
  - Có cơ chế clear lỗi rõ ràng (`clearErrorMessage` hoặc method riêng).

## 5. Quy ước Notifier
- Notifier chỉ xử lý orchestration state + gọi usecase.
- Không gọi API trực tiếp trong Notifier; chỉ gọi qua usecase/repository abstraction.
- Side effect phải được đặt trong method có tên rõ nghĩa:
  - `syncInitial`, `refresh`, `loadMore`, `submit`, `retry`, `clearError`.
- Có guard tránh call trùng:
  - Không `loadMore` khi đang loading.
  - Không submit lặp khi đang submit.
- Không để `BuildContext` trong Notifier.

## 6. Quy ước Provider
- Provider được khai báo tại file `{feature}_provider.dart`.
- Không tạo provider trong `build` method.
- Sử dụng đúng loại provider:
  - `Provider`: dependency thuần (usecase/service/repository bridge).
  - `StateNotifierProvider`: state phức tạp có nhiều transition.
  - `FutureProvider`: fetch đơn giản không cần mutation flow.
  - `StreamProvider`: event stream/lifecycle stream.
- Provider tên theo hậu tố:
  - `...Provider` cho dependency/state.
  - `...NotifierProvider` cho `StateNotifier`.

## 7. Quy ước UI binding
- UI chỉ đọc state bằng `ref.watch(...)`.
- UI gọi action bằng `ref.read(notifierProvider.notifier)`.
- Không chứa business logic trong Widget:
  - Widget chỉ render + trigger action.
  - Rule/domain decision nằm ở usecase/notifier.
- Tránh rebuild thừa:
  - Dùng `select()` khi chỉ cần một field.
  - Tách widget nhỏ theo phần state cần watch.

## 8. Quy ước dependency theo layer
- Luồng bắt buộc: `Presentation -> Domain -> Data`.
- UI không import data layer.
- Không inject `Dio` trực tiếp vào Widget.
- Không bypass repository/usecase.

## 9. Migration checklist cho mỗi module
- Tạo `state/` theo naming chuẩn.
- Tạo immutable `State` + `copyWith`.
- Tạo `Notifier` gọi usecase hiện có, không đổi business rule.
- Tạo `Provider` inject dependencies từ app provider graph.
- Đổi UI từ `setState`/`ChangeNotifier` sang `ref.watch`/`ref.read`.
- Giữ nguyên behavior, route, thông điệp lỗi, API contract.
- Bổ sung unit test state transition cho notifier.

## 10. Definition of Done (mức module)
- Không còn `setState` trong phạm vi module đã migrate.
- Không đổi business behavior và navigation flow.
- Không phát sinh duplicate API call ngoài hành vi cũ.
- `flutter analyze` sạch cho các file module đã migrate.
- Có test cho các transition quan trọng của notifier.

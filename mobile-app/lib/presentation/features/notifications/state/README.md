# Notification State Convention (Riverpod Migration)

Tài liệu này chuẩn hóa cách migrate module Notification từ `ChangeNotifier` sang Riverpod.

## 1. File chuẩn trong thư mục state
- `notification_state.dart`: immutable state, giữ shape dữ liệu UI.
- `notification_notifier.dart`: xử lý transition state và orchestration usecase.
- `notification_provider.dart`: khai báo provider cho state/notifier/dependency.

## 2. Mapping từ hiện trạng sang chuẩn mới
- `NotificationProvider(ChangeNotifier)` hiện tại sẽ được thay bằng `NotificationNotifier(StateNotifier<NotificationState>)`.
- Logic nghiệp vụ giữ nguyên:
  - `syncInitial`
  - `refresh`
  - `loadMore`
  - `markAsRead`
  - `markAllAsRead`
  - `reloadUnreadCount`
  - `applyIncomingPush`
- Không thay đổi contract usecase đang dùng trong module.

## 3. Quy ước state cho notification
- `NotificationState` giữ immutable và `copyWith`.
- Không mutate list/set trực tiếp:
  - luôn tạo collection mới trước khi emit state.
- Trạng thái loading được tách riêng:
  - `isInitialLoading`, `isRefreshing`, `isLoadingMore`, `isMarkingAllAsRead`.

## 4. Quy ước UI binding
- Page dùng `ref.watch(notificationNotifierProvider)` để render state.
- Action UI gọi qua `ref.read(notificationNotifierProvider.notifier)`.
- Không gọi usecase trực tiếp từ Widget.

## 5. Nguồn chuẩn chung
- Quy ước tổng thể: `docs/RIVERPOD_STATE_NOTIFIER_CONVENTION.md`.

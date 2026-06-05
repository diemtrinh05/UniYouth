class AppRoutes {
  const AppRoutes._();

  // Khai báo route name tập trung để tránh hard-code rải rác.
  static const splash = '/splash';
  static const login = '/login';
  static const forgotPassword = '/auth/forgot-password';
  static const enterOtp = '/auth/enter-otp';
  static const resetPassword = '/auth/reset-password';
  static const devApiConfig = '/dev-api-config';
  static const app = '/app';
  static const home = '/home';
  static const eventFilters = '/events/filters';
  static const eventList = '/events';
  static const eventDetail = '/events/detail';
  static const attendanceQrScan = '/attendance/qr-scan';
  static const attendanceHistory = '/attendance/history';
  static const pointsSummary = '/points/summary';
  static const pointsHistory = '/points/history';
  static const notifications = '/notifications';
  static const supportChat = '/support-chat';
  static const supportChatDetail = '/support-chat/detail';
  static const profileView = '/profile/view';
  static const profileEdit = '/profile/edit';
  static const profileChangePassword = '/profile/change-password';
}

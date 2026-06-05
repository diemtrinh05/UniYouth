import 'package:dio/dio.dart';

class NetworkRetryPolicy {
  const NetworkRetryPolicy({
    this.maxRetryCount = 1,
    this.baseDelay = const Duration(milliseconds: 250),
  });

  final int maxRetryCount;
  final Duration baseDelay;

  static final RegExp _registerEndpointPattern = RegExp(
    r'^/api/events/\d+/register$',
  );

  bool shouldRetry({required DioException error, required int retryCount}) {
    if (retryCount >= maxRetryCount) {
      return false;
    }

    if (!_isTransientNetworkFailure(error.type)) {
      return false;
    }

    final method = error.requestOptions.method.trim().toUpperCase();
    final path = error.requestOptions.path.trim().toLowerCase();

    // Sensitive APIs must never auto-retry to avoid uncontrolled duplicates.
    if (_isSensitiveEndpoint(method: method, path: path)) {
      return false;
    }

    // Retry only safe methods.
    if (!_isSafeHttpMethod(method)) {
      return false;
    }

    return true;
  }

  Duration delayForRetry({required int retryCount}) {
    final multiplier = retryCount + 1;
    return Duration(milliseconds: baseDelay.inMilliseconds * multiplier);
  }

  bool _isTransientNetworkFailure(DioExceptionType type) {
    switch (type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      default:
        return false;
    }
  }

  bool _isSafeHttpMethod(String method) {
    return method == 'GET' || method == 'HEAD' || method == 'OPTIONS';
  }

  bool _isSensitiveEndpoint({required String method, required String path}) {
    if (method != 'POST') {
      return false;
    }

    if (path.endsWith('/api/auth/login')) {
      return true;
    }

    if (_registerEndpointPattern.hasMatch(path)) {
      return true;
    }

    if (path.endsWith('/api/attendance/checkin')) {
      return true;
    }

    return false;
  }
}

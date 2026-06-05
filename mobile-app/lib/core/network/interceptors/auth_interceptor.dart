import 'package:dio/dio.dart';

import '../auth_token_provider.dart';

const _authorizationHeader = 'Authorization';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required AuthTokenProvider tokenProvider,
    required Dio Function() dioProvider,
    Future<bool> Function()? tryRefreshToken,
    Future<void> Function()? onUnauthorized,
  }) : _tokenProvider = tokenProvider,
       _dioProvider = dioProvider,
       _tryRefreshToken = tryRefreshToken,
       _onUnauthorized = onUnauthorized;

  final AuthTokenProvider _tokenProvider;
  final Dio Function() _dioProvider;
  final Future<bool> Function()? _tryRefreshToken;
  final Future<void> Function()? _onUnauthorized;
  Future<bool>? _refreshInFlight;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_isAnonymousPasswordRecoveryRequest(options) ||
        options.extra['skipAuthorization'] == true) {
      options.headers.remove(_authorizationHeader);
      handler.next(options);
      return;
    }

    final accessToken = await _tokenProvider.getAccessToken();
    final hasToken = accessToken != null && accessToken.trim().isNotEmpty;
    final hasAuthorizationHeader = options.headers.containsKey(
      _authorizationHeader,
    );

    if (hasToken && !hasAuthorizationHeader) {
      options.headers[_authorizationHeader] = 'Bearer $accessToken';
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;
    if (statusCode == 401 && _shouldHandleUnauthorized(err.requestOptions)) {
      final refreshed = await _refreshAccessTokenIfNeeded();
      if (refreshed) {
        try {
          final retriedResponse = await _retryRequest(err.requestOptions);
          handler.resolve(retriedResponse);
          return;
        } on DioException catch (_) {}
      }
      await _onUnauthorized?.call();
    }
    handler.next(err);
  }

  bool _shouldHandleUnauthorized(RequestOptions options) {
    if (options.extra['skipAuthRefresh'] == true) {
      return false;
    }

    final hasAuthorizationHeader = options.headers.containsKey(
      _authorizationHeader,
    );
    if (!hasAuthorizationHeader) {
      return false;
    }

    if (_isAnonymousPasswordRecoveryRequest(options) ||
        options.path.toLowerCase().endsWith('/api/auth/login')) {
      return false;
    }

    return true;
  }

  bool _isAnonymousPasswordRecoveryRequest(RequestOptions options) {
    final normalizedPath = options.path.toLowerCase();
    return normalizedPath.endsWith('/api/auth/forgot-password') ||
        normalizedPath.endsWith('/api/auth/verify-reset-otp') ||
        normalizedPath.endsWith('/api/auth/reset-password') ||
        normalizedPath.endsWith('/api/auth/refresh') ||
        normalizedPath.endsWith('/api/auth/revoke');
  }

  Future<bool> _refreshAccessTokenIfNeeded() async {
    if (_tryRefreshToken == null) {
      return false;
    }

    if (_refreshInFlight != null) {
      return _refreshInFlight!;
    }

    final future = _tryRefreshToken();
    _refreshInFlight = future;
    try {
      return await future;
    } finally {
      if (identical(_refreshInFlight, future)) {
        _refreshInFlight = null;
      }
    }
  }

  Future<Response<dynamic>> _retryRequest(RequestOptions requestOptions) async {
    final accessToken = await _tokenProvider.getAccessToken();
    if (accessToken == null || accessToken.trim().isEmpty) {
      throw DioException(
        requestOptions: requestOptions,
        error: 'Missing refreshed access token.',
      );
    }

    final nextHeaders = Map<String, dynamic>.from(requestOptions.headers)
      ..[_authorizationHeader] = 'Bearer $accessToken';
    final nextExtra = Map<String, dynamic>.from(requestOptions.extra)
      ..['skipAuthRefresh'] = true;

    final nextOptions = requestOptions.copyWith(
      headers: nextHeaders,
      extra: nextExtra,
    );

    return _dioProvider().fetch<dynamic>(nextOptions);
  }
}

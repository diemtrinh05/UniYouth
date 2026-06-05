import 'package:dio/dio.dart';

import 'auth_token_provider.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';

class AppDio {
  AppDio._();

  static Dio? _sharedDio;
  static String? _sharedBaseUrl;

  static Dio getSharedInstance({
    required String baseUrl,
    required AuthTokenProvider tokenProvider,
    Future<bool> Function()? tryRefreshToken,
    Future<void> Function()? onUnauthorized,
    Duration connectTimeout = const Duration(seconds: 30),
    Duration sendTimeout = const Duration(seconds: 30),
    Duration receiveTimeout = const Duration(seconds: 30),
  }) {
    if (_sharedDio == null) {
      _sharedDio = _buildDio(
        baseUrl: baseUrl,
        tokenProvider: tokenProvider,
        tryRefreshToken: tryRefreshToken,
        onUnauthorized: onUnauthorized,
        connectTimeout: connectTimeout,
        sendTimeout: sendTimeout,
        receiveTimeout: receiveTimeout,
      );
      _sharedBaseUrl = baseUrl;
    } else if (_sharedBaseUrl != baseUrl) {
      updateBaseUrl(baseUrl);
    }

    return _sharedDio!;
  }

  static Dio _buildDio({
    required String baseUrl,
    required AuthTokenProvider tokenProvider,
    Future<bool> Function()? tryRefreshToken,
    Future<void> Function()? onUnauthorized,
    required Duration connectTimeout,
    required Duration sendTimeout,
    required Duration receiveTimeout,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: connectTimeout,
        sendTimeout: sendTimeout,
        receiveTimeout: receiveTimeout,
        responseType: ResponseType.json,
        contentType: Headers.jsonContentType,
        headers: <String, Object>{
          Headers.acceptHeader: Headers.jsonContentType,
        },
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(
        tokenProvider: tokenProvider,
        dioProvider: () => _sharedDio ?? dio,
        tryRefreshToken: tryRefreshToken,
        onUnauthorized: onUnauthorized,
      ),
      ErrorInterceptor(),
    ]);

    return dio;
  }

  static Dio createPlainInstance({
    required String baseUrl,
    Duration connectTimeout = const Duration(seconds: 30),
    Duration sendTimeout = const Duration(seconds: 30),
    Duration receiveTimeout = const Duration(seconds: 30),
  }) {
    return Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: connectTimeout,
        sendTimeout: sendTimeout,
        receiveTimeout: receiveTimeout,
        responseType: ResponseType.json,
        contentType: Headers.jsonContentType,
        headers: <String, Object>{
          Headers.acceptHeader: Headers.jsonContentType,
        },
      ),
    )..interceptors.add(ErrorInterceptor());
  }

  static void updateBaseUrl(String baseUrl) {
    _sharedBaseUrl = baseUrl;
    _sharedDio?.options.baseUrl = baseUrl;
  }

  static void resetSharedInstance() {
    _sharedDio = null;
    _sharedBaseUrl = null;
  }
}

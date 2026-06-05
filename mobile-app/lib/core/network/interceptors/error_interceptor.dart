import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../error/app_error.dart';
import '../../error/app_error_parser.dart';

class ErrorInterceptor extends Interceptor {
  static const bool _isProduct = bool.fromEnvironment('dart.vm.product');
  static const int _maxLoggedBodyLength = 4000;
  static const String _redacted = '***REDACTED***';
  static const Set<String> _sensitiveFieldKeys = <String>{
    'token',
    'access_token',
    'accesstoken',
    'refresh_token',
    'refreshtoken',
    'otpcode',
    'password',
    'currentpassword',
    'newpassword',
    'confirmnewpassword',
    'verificationticket',
  };

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _logTraceHeadersIfPresent(
      requestOptions: response.requestOptions,
      headers: response.headers,
      statusCode: response.statusCode,
    );
    _logResponseBody(
      requestOptions: response.requestOptions,
      statusCode: response.statusCode,
      body: response.data,
      phase: 'response',
    );

    final responseBody = _asStringDynamicMap(response.data);

    if (responseBody != null && responseBody['success'] == false) {
      final parsedError = AppErrorParser.fromResponse(
        statusCode: response.statusCode,
        data: response.data,
        fallbackMessage: 'ApiResponseDto indicates failure.',
      );

      handler.reject(
        DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: parsedError,
          message: parsedError.message,
        ),
      );
      return;
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;
    if (response != null) {
      _logTraceHeadersIfPresent(
        requestOptions: response.requestOptions,
        headers: response.headers,
        statusCode: response.statusCode,
      );
      _logResponseBody(
        requestOptions: response.requestOptions,
        statusCode: response.statusCode,
        body: response.data,
        phase: 'error_response',
      );
    }

    if (err.error is AppError) {
      handler.next(err);
      return;
    }

    final parsedError = AppErrorParser.fromDioException(err);
    handler.next(
      err.copyWith(error: parsedError, message: parsedError.message),
    );
  }

  void _logResponseBody({
    required RequestOptions requestOptions,
    required int? statusCode,
    required Object? body,
    required String phase,
  }) {
    if (_isProduct) return;

    final method = requestOptions.method.toUpperCase();
    final path = requestOptions.uri.path;
    final maskedBody = _maskSensitiveData(body);
    final encodedBody = _encodeBody(maskedBody);
    final shortenedBody = _truncate(encodedBody, _maxLoggedBodyLength);

    developer.log(
      'http_body phase=$phase method=$method path=$path status=$statusCode body=$shortenedBody',
      name: 'observability',
    );
  }

  void _logTraceHeadersIfPresent({
    required RequestOptions requestOptions,
    required Headers headers,
    required int? statusCode,
  }) {
    if (_isProduct) return;

    final traceId = _firstHeaderValue(headers, const <String>['X-Trace-Id']);
    final idempotencyReplayed = _firstHeaderValue(headers, const <String>[
      'Idempotency-Replayed',
    ]);

    if (traceId == null && idempotencyReplayed == null) {
      return;
    }

    final method = requestOptions.method.toUpperCase();
    final path = requestOptions.uri.path;
    developer.log(
      'http_headers method=$method path=$path status=$statusCode '
      'traceId=${traceId ?? "-"} idempotencyReplayed=${idempotencyReplayed ?? "-"}',
      name: 'observability',
    );
  }

  String? _firstHeaderValue(Headers headers, List<String> candidates) {
    for (final key in candidates) {
      final value = headers.value(key);
      if (value == null) continue;
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }

  Map<String, dynamic>? _asStringDynamicMap(Object? data) {
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }

    if (data is String) {
      final trimmed = data.trim();
      if (trimmed.isEmpty) {
        return null;
      }
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map) {
          return decoded.map((key, value) => MapEntry(key.toString(), value));
        }
      } on FormatException {
        return null;
      }
    }

    return null;
  }

  Object? _maskSensitiveData(Object? data) {
    if (data is Map) {
      return data.map((key, value) {
        final normalizedKey = key.toString();
        final normalizedKeyLower = normalizedKey.toLowerCase();
        if (_sensitiveFieldKeys.contains(normalizedKeyLower)) {
          return MapEntry(normalizedKey, _redacted);
        }
        return MapEntry(normalizedKey, _maskSensitiveData(value));
      });
    }

    if (data is List) {
      return data.map(_maskSensitiveData).toList(growable: false);
    }

    return data;
  }

  String _encodeBody(Object? body) {
    if (body == null) {
      return '<null>';
    }
    if (body is String) {
      final trimmed = body.trim();
      return trimmed.isEmpty ? '<empty>' : trimmed;
    }
    try {
      return jsonEncode(body);
    } catch (_) {
      return body.toString();
    }
  }

  String _truncate(String value, int maxLength) {
    if (value.length <= maxLength) {
      return value;
    }
    return '${value.substring(0, maxLength)}...<truncated>';
  }
}

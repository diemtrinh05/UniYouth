import 'dart:convert';

import 'package:dio/dio.dart';

import 'app_error.dart';
import 'app_error_type.dart';
import 'http_status_error_mapper.dart';

class AppErrorParser {
  const AppErrorParser._();

  static AppError fromResponse({
    required int? statusCode,
    required Object? data,
    String fallbackMessage = 'Request failed.',
  }) {
    final body = _asStringDynamicMap(data);

    if (body != null) {
      final rateLimitError = _tryParseRateLimitBody(
        statusCode: statusCode,
        body: body,
      );
      if (rateLimitError != null) {
        return rateLimitError;
      }

      if (_isApiResponseFailure(body)) {
        return _fromApiResponseFailure(statusCode: statusCode, body: body);
      }

      if (_isProblemDetails(body)) {
        return _fromProblemDetails(statusCode: statusCode, body: body);
      }
    }

    return AppError(
      type: mapStatusCodeToErrorType(statusCode),
      statusCode: statusCode,
      message: fallbackMessage,
    );
  }

  static AppError fromDioException(DioException exception) {
    final response = exception.response;

    if (response != null) {
      return fromResponse(
        statusCode: response.statusCode,
        data: response.data,
        fallbackMessage: exception.message ?? 'Request failed.',
      );
    }

    return AppError(
      type: AppErrorType.network,
      message: _networkMessage(exception),
    );
  }

  static bool _isApiResponseFailure(Map<String, dynamic> body) {
    return body.containsKey('success') && body['success'] == false;
  }

  static bool _isProblemDetails(Map<String, dynamic> body) {
    return body.containsKey('title') || body.containsKey('detail');
  }

  static AppError? _tryParseRateLimitBody({
    required int? statusCode,
    required Map<String, dynamic> body,
  }) {
    // Backend rate-limiter returns a standalone object:
    // { "message": "...", "statusCode": 429 }
    final rawMessage = body['message'];
    final message = rawMessage is String ? rawMessage.trim() : null;

    final rawStatus = body['statusCode'];
    final parsedBodyStatus = _readInt(rawStatus);
    final resolvedStatus = parsedBodyStatus ?? statusCode;

    if (resolvedStatus != 429) {
      return null;
    }

    if (message == null || message.isEmpty) {
      return AppError(
        type: mapStatusCodeToErrorType(resolvedStatus),
        statusCode: resolvedStatus,
        message: 'Too many requests.',
      );
    }

    return AppError(
      type: mapStatusCodeToErrorType(resolvedStatus),
      statusCode: resolvedStatus,
      message: message,
      isBackendMessage: true,
    );
  }

  static AppError _fromApiResponseFailure({
    required int? statusCode,
    required Map<String, dynamic> body,
  }) {
    final fieldErrors = _parseFieldErrors(body['errors']);
    final message =
        _readString(body['message']) ??
        _firstFieldError(fieldErrors) ??
        'Request failed.';

    return AppError(
      type: mapStatusCodeToErrorType(statusCode),
      statusCode: statusCode,
      message: message,
      fieldErrors: fieldErrors,
      isBackendMessage: true,
    );
  }

  static AppError _fromProblemDetails({
    required int? statusCode,
    required Map<String, dynamic> body,
  }) {
    final problemStatus = _readInt(body['status']);
    final resolvedStatus = problemStatus ?? statusCode;
    final detail = _readString(body['detail']);
    final title = _readString(body['title']);
    final fieldErrors = _parseFieldErrors(body['errors']);

    return AppError(
      type: mapStatusCodeToErrorType(resolvedStatus),
      statusCode: resolvedStatus,
      message:
          detail ?? title ?? _firstFieldError(fieldErrors) ?? 'Request failed.',
      backendType: _readString(body['type']),
      title: title,
      detail: detail,
      fieldErrors: fieldErrors,
      isBackendMessage: true,
    );
  }

  static Map<String, List<String>>? _parseFieldErrors(Object? rawErrors) {
    if (rawErrors is! Map) {
      return null;
    }

    final parsed = <String, List<String>>{};
    rawErrors.forEach((key, value) {
      final normalizedKey = key.toString();
      if (value is List) {
        final messages = value.map((item) => item.toString()).toList();
        if (messages.isNotEmpty) {
          parsed[normalizedKey] = messages;
        }
      } else if (value != null) {
        parsed[normalizedKey] = [value.toString()];
      }
    });

    return parsed.isEmpty ? null : parsed;
  }

  static String? _firstFieldError(Map<String, List<String>>? fieldErrors) {
    if (fieldErrors == null || fieldErrors.isEmpty) {
      return null;
    }

    for (final entry in fieldErrors.values) {
      if (entry.isNotEmpty) {
        return entry.first;
      }
    }

    return null;
  }

  static Map<String, dynamic>? _asStringDynamicMap(Object? data) {
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

  static String? _readString(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    return null;
  }

  static int? _readInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  static String _networkMessage(DioException exception) {
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Request timeout.';
      case DioExceptionType.connectionError:
        return 'Connection error.';
      case DioExceptionType.cancel:
        return 'Request cancelled.';
      default:
        return exception.message ?? 'Network error.';
    }
  }
}

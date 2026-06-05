import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../models/attendance/attendance_history_item_model.dart';
import '../../models/attendance/check_in_requirements_model.dart';
import '../../models/attendance/check_attendance_status_model.dart';
import '../../models/attendance/check_in_request_model.dart';
import '../../models/attendance/check_in_result_model.dart';
import '../../models/events/event_detail_model.dart';
import '../../models/events/event_list_item_model.dart';
import '../../models/registration/registration_result_model.dart';
import 'base_remote_datasource.dart';

class EventsRemoteDataSource extends BaseRemoteDataSource {
  EventsRemoteDataSource({required Dio dio}) : super(dio);

  void _logContractDrift({
    required String operation,
    required int? statusCode,
    required Object? data,
    Object? error,
  }) {
    const isRelease = bool.fromEnvironment('dart.vm.product');
    if (isRelease) {
      return;
    }

    final dataType = data == null ? 'null' : data.runtimeType.toString();
    final dataLength = data is String ? data.length : null;

    developer.log(
      'Contract drift: success response is missing/invalid payload. '
      'operation=$operation statusCode=$statusCode dataType=$dataType dataLength=$dataLength',
      name: 'uniyouth.contract_drift',
      error: error,
    );
  }

  Future<CheckAttendanceStatusModel> getAttendanceCheckStatus({
    required int eventId,
  }) async {
    final response = await runRequest(
      () => dio.get<dynamic>(
        '/api/attendance/check-status/$eventId',
        options: Options(responseType: ResponseType.plain),
      ),
    );

    final typedBody = _asStringDynamicMap(
      response.data,
      fallbackMessage: 'Invalid attendance check-status response body.',
    );
    return CheckAttendanceStatusModel.fromApiResponse(typedBody);
  }

  Future<AttendanceHistoryPageModel> getMyAttendanceHistory({
    required int pageNumber,
    required int pageSize,
  }) async {
    final response = await runRequest(
      () => dio.get<dynamic>(
        '/api/attendance/my-history',
        queryParameters: <String, dynamic>{
          'pageNumber': pageNumber,
          'pageSize': pageSize,
        },
        options: Options(responseType: ResponseType.plain),
      ),
    );

    final typedBody = _asStringDynamicMap(
      response.data,
      fallbackMessage: 'Invalid attendance history response body.',
    );
    return AttendanceHistoryPageModel.fromApiResponse(typedBody);
  }

  Future<EventListPageModel> getEvents({
    required int pageNumber,
    required int pageSize,
    String? q,
    int? status,
    String? sortBy,
    String? sortDir,
    int? eventTypeId,
    int? instituteId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParameters = <String, dynamic>{
      'pageNumber': pageNumber,
      'pageSize': pageSize,
    };

    if (q != null && q.trim().isNotEmpty) {
      queryParameters['q'] = q.trim();
    }
    if (status != null) {
      queryParameters['status'] = status;
    }
    if (sortBy != null && sortBy.trim().isNotEmpty) {
      queryParameters['sortBy'] = sortBy;
    }
    if (sortDir != null && sortDir.trim().isNotEmpty) {
      queryParameters['sortDir'] = sortDir;
    }
    if (eventTypeId != null) {
      queryParameters['eventTypeId'] = eventTypeId;
    }
    if (instituteId != null) {
      queryParameters['instituteId'] = instituteId;
    }
    if (startDate != null) {
      queryParameters['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      queryParameters['endDate'] = endDate.toIso8601String();
    }

    final response = await runRequest(
      () => dio.get<dynamic>('/api/Events', queryParameters: queryParameters),
    );

    final body = response.data;
    if (body is! Map) {
      throw const FormatException('Invalid event list response body.');
    }

    final typedBody = body.map((key, value) => MapEntry(key.toString(), value));

    // Support both direct paginated payload and ApiResponseDto envelope.
    final envelopeData = typedBody['data'];
    if (envelopeData is Map) {
      final mappedData = envelopeData.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      return EventListPageModel.fromJson(mappedData);
    }

    return EventListPageModel.fromJson(typedBody);
  }

  Future<EventDetailModel> getEventDetail({required int eventId}) async {
    final response = await runRequest(
      () => dio.get<dynamic>('/api/Events/$eventId'),
    );

    final body = response.data;
    if (body is! Map) {
      throw const FormatException('Invalid event detail response body.');
    }

    final typedBody = body.map((key, value) => MapEntry(key.toString(), value));
    return EventDetailModel.fromApiResponse(typedBody);
  }

  Future<RegistrationResultModel> getMyRegistration({
    required int eventId,
  }) async {
    final response = await runRequest(
      () => dio.get<dynamic>(
        '/api/events/$eventId/my-registration',
        options: Options(responseType: ResponseType.plain),
      ),
    );

    final typedBody = _asStringDynamicMap(
      response.data,
      fallbackMessage: 'Invalid my registration response body.',
    );
    return RegistrationResultModel.fromApiResponse(typedBody);
  }

  Future<RegistrationResultModel> registerEvent({
    required int eventId,
    required String idempotencyKey,
  }) async {
    final response = await runRequest(
      () => dio.post<dynamic>(
        '/api/events/$eventId/register',
        options: Options(
          headers: <String, Object>{'Idempotency-Key': idempotencyKey},
          responseType: ResponseType.plain,
        ),
      ),
    );

    Map<String, dynamic> typedBody;
    try {
      typedBody = _asStringDynamicMap(
        response.data,
        fallbackMessage: 'Invalid register event response body.',
      );
    } on FormatException catch (error) {
      // Swagger defines a response body, but keep the flow resilient if backend returns 2xx without payload.
      if (_isSuccessStatus(response.statusCode)) {
        _logContractDrift(
          operation: 'POST /api/events/$eventId/register',
          statusCode: response.statusCode,
          data: response.data,
          error: error,
        );
        return _emptyRegistrationResult(eventId: eventId);
      }
      rethrow;
    }
    try {
      return RegistrationResultModel.fromApiResponse(typedBody);
    } on FormatException catch (error) {
      // Keep flow resilient if backend returns success without full payload.
      if (_isSuccessStatus(response.statusCode)) {
        _logContractDrift(
          operation: 'POST /api/events/$eventId/register',
          statusCode: response.statusCode,
          data: response.data,
          error: error,
        );
        return _emptyRegistrationResult(eventId: eventId);
      }
      rethrow;
    }
  }

  Future<RegistrationResultModel> cancelRegistration({
    required int eventId,
    String? cancellationReason,
  }) async {
    final requestBody = <String, dynamic>{};
    final normalizedReason = cancellationReason?.trim();
    if (normalizedReason != null && normalizedReason.isNotEmpty) {
      requestBody['cancellationReason'] = normalizedReason;
    }

    final response = await runRequest(
      () => dio.delete<dynamic>(
        '/api/events/$eventId/register',
        data: requestBody,
        options: Options(responseType: ResponseType.plain),
      ),
    );

    Map<String, dynamic> typedBody;
    try {
      typedBody = _asStringDynamicMap(
        response.data,
        fallbackMessage: 'Invalid cancel registration response body.',
      );
    } on FormatException catch (error) {
      // Swagger defines a response body, but keep the flow resilient if backend returns 2xx without payload.
      if (_isSuccessStatus(response.statusCode)) {
        _logContractDrift(
          operation: 'DELETE /api/events/$eventId/register',
          statusCode: response.statusCode,
          data: response.data,
          error: error,
        );
        return _emptyRegistrationResult(eventId: eventId);
      }
      rethrow;
    }
    try {
      return RegistrationResultModel.fromApiResponse(typedBody);
    } on FormatException catch (error) {
      // Keep flow resilient if backend returns success without full payload.
      if (_isSuccessStatus(response.statusCode)) {
        _logContractDrift(
          operation: 'DELETE /api/events/$eventId/register',
          statusCode: response.statusCode,
          data: response.data,
          error: error,
        );
        return _emptyRegistrationResult(eventId: eventId);
      }
      rethrow;
    }
  }

  Future<CheckInResultModel> checkIn({
    required String qrToken,
    required double latitude,
    required double longitude,
    required String idempotencyKey,
    String? deviceInfo,
    String? clientDeviceId,
    String? faceImageBase64,
    String? faceImageMimeType,
    LivenessCheckPayloadModel? liveness,
  }) async {
    final response = await runRequest(
      () => dio.post<dynamic>(
        '/api/attendance/checkin',
        data: CheckInRequestModel(
          qrToken: qrToken,
          latitude: latitude,
          longitude: longitude,
          deviceInfo: deviceInfo,
          clientDeviceId: clientDeviceId,
          faceImageBase64: faceImageBase64,
          faceImageMimeType: faceImageMimeType,
          liveness: liveness,
        ).toJson(),
        options: Options(
          headers: <String, Object>{'Idempotency-Key': idempotencyKey},
          responseType: ResponseType.plain,
        ),
      ),
    );

    final typedBody = _asStringDynamicMap(
      response.data,
      fallbackMessage: 'Invalid check-in response body.',
    );
    return CheckInResultModel.fromApiResponse(typedBody);
  }

  Future<CheckInRequirementsModel> getCheckInRequirements({
    required String qrToken,
  }) async {
    final response = await runRequest(
      () => dio.post<dynamic>(
        '/api/attendance/checkin/requirements',
        data: <String, dynamic>{'qrToken': qrToken},
        options: Options(responseType: ResponseType.plain),
      ),
    );

    final typedBody = _asStringDynamicMap(
      response.data,
      fallbackMessage: 'Invalid check-in requirements response body.',
    );
    return CheckInRequirementsModel.fromApiResponse(typedBody);
  }

  Map<String, dynamic> _asStringDynamicMap(
    Object? data, {
    required String fallbackMessage,
  }) {
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }

    // Swagger allows `text/plain` responses; Dio may return JSON as a string.
    if (data is String) {
      final trimmed = data.trim();
      if (trimmed.isNotEmpty) {
        try {
          final decoded = jsonDecode(trimmed);
          if (decoded is Map) {
            return decoded.map((key, value) => MapEntry(key.toString(), value));
          }
        } on FormatException {
          // Fall through to throw below.
        }
      }
    }

    throw FormatException(fallbackMessage);
  }

  bool _isSuccessStatus(int? statusCode) {
    if (statusCode == null) {
      return false;
    }
    return statusCode >= 200 && statusCode < 300;
  }

  RegistrationResultModel _emptyRegistrationResult({required int eventId}) {
    return RegistrationResultModel(
      registrationId: 0,
      eventId: eventId,
      eventName: null,
      userId: 0,
      userFullName: null,
      registerTime: null,
      status: null,
      cancellationReason: null,
      createdDate: null,
    );
  }
}

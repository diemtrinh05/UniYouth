import '../../core/error/app_error.dart';
import '../../core/error/app_error_type.dart';
import '../../core/network/idempotency_key_provider.dart';
import '../../domain/entities/registration/registration_status.dart';
import '../../domain/usecases/attendance/check_in_usecase.dart';
import '../../domain/usecases/attendance/check_attendance_status_usecase.dart';
import '../../domain/usecases/attendance/get_check_in_requirements_usecase.dart';
import '../../domain/usecases/attendance/get_my_history_usecase.dart';
import '../../domain/usecases/events/get_event_detail_usecase.dart';
import '../../domain/usecases/events/get_events_usecase.dart';
import '../../domain/usecases/registration/cancel_registration_usecase.dart';
import '../../domain/usecases/registration/get_my_registration_usecase.dart';
import '../../domain/usecases/registration/register_event_usecase.dart';
import '../models/attendance/check_in_request_model.dart';
import '../datasources/remote/events_remote_datasource.dart';

class EventsRepositoryImpl
    implements
        EventsRepository,
        EventDetailRepository,
        MyRegistrationRepository,
        RegisterEventRepository,
        CancelRegistrationRepository,
        CheckInRepository,
        CheckInRequirementsRepository,
        CheckAttendanceStatusRepository,
        GetMyHistoryRepository {
  static const Duration _idempotencyKeyTtl = Duration(seconds: 60);

  EventsRepositoryImpl({
    required EventsRemoteDataSource remoteDataSource,
    required IdempotencyKeyProvider idempotencyKeyProvider,
  }) : _remoteDataSource = remoteDataSource,
       _idempotencyKeyProvider = idempotencyKeyProvider;

  final EventsRemoteDataSource _remoteDataSource;
  final IdempotencyKeyProvider _idempotencyKeyProvider;

  final Map<String, _IdempotencyKeyCacheEntry> _idempotencyKeyCache =
      <String, _IdempotencyKeyCacheEntry>{};

  String _getOrCreateIdempotencyKey({
    required String fingerprint,
    required String scope,
  }) {
    final now = DateTime.now();
    final cached = _idempotencyKeyCache[fingerprint];
    if (cached != null &&
        now.difference(cached.createdAt) <= _idempotencyKeyTtl) {
      return cached.key;
    }

    final key = _idempotencyKeyProvider.generateKey(scope: scope);
    _idempotencyKeyCache[fingerprint] = _IdempotencyKeyCacheEntry(
      key: key,
      createdAt: now,
    );
    return key;
  }

  void _clearIdempotencyKey(String fingerprint) {
    _idempotencyKeyCache.remove(fingerprint);
  }

  bool _shouldKeepIdempotencyKeyOnError(AppError error) {
    // Keep the same key only when we don't know if the request reached backend
    // (transient network failures). This makes the action retry-safe.
    return error.type == AppErrorType.network;
  }

  @override
  Future<EventListPageResult> getEvents({
    required EventListFilter filter,
  }) async {
    final response = await _remoteDataSource.getEvents(
      pageNumber: filter.pageNumber,
      pageSize: filter.pageSize,
      q: filter.q,
      status: filter.status,
      sortBy: filter.sortBy,
      sortDir: filter.sortDir,
      eventTypeId: filter.eventTypeId,
      instituteId: filter.instituteId,
      startDate: filter.startDate,
      endDate: filter.endDate,
    );

    // Repository map data model sang domain model trước khi trả cho use case.
    final items = response.items
        .map(
          (item) => EventListItem(
            eventId: item.eventId,
            eventName: item.eventName,
            description: item.description,
            startTime: item.startTime,
            endTime: item.endTime,
            locationName: item.locationName,
            maxParticipants: item.maxParticipants,
            currentParticipants: item.currentParticipants,
            status: item.status,
            statusName: item.statusName,
            eventTypeName: item.eventTypeName,
            instituteName: item.instituteName,
            registrationDeadline: item.registrationDeadline,
            thumbnailUrl: item.thumbnailUrl,
            hasAvailableSlots: item.hasAvailableSlots,
          ),
        )
        .toList(growable: false);

    return EventListPageResult(
      items: items,
      totalCount: response.totalCount,
      pageNumber: response.pageNumber,
      pageSize: response.pageSize,
      totalPages: response.totalPages,
      hasPreviousPage: response.hasPreviousPage,
      hasNextPage: response.hasNextPage,
    );
  }

  @override
  Future<EventDetail> getEventDetail({required int eventId}) async {
    final response = await _remoteDataSource.getEventDetail(eventId: eventId);

    // Keep UI layer detached from API model by mapping into domain type.
    return EventDetail(
      eventId: response.eventId,
      eventName: response.eventName,
      description: response.description,
      startTime: response.startTime,
      endTime: response.endTime,
      locationName: response.locationName,
      latitude: response.latitude,
      longitude: response.longitude,
      allowRadius: response.allowRadius,
      maxParticipants: response.maxParticipants,
      currentParticipants: response.currentParticipants,
      status: response.status,
      statusName: response.statusName,
      eventType: response.eventType != null
          ? EventDetailTypeInfo(
              typeId: response.eventType!.typeId,
              typeName: response.eventType!.typeName,
              description: response.eventType!.description,
            )
          : null,
      institute: response.institute != null
          ? EventDetailInstituteInfo(
              instituteId: response.institute!.instituteId,
              instituteName: response.institute!.instituteName,
            )
          : null,
      registrationDeadline: response.registrationDeadline,
      images: response.images
          .map(
            (image) => EventDetailImage(
              imageId: image.imageId,
              imageUrl: image.imageUrl,
              imageType: image.imageType,
              caption: image.caption,
              displayOrder: image.displayOrder,
            ),
          )
          .toList(growable: false),
      createdByName: response.createdByName,
      createdDate: response.createdDate,
      hasAvailableSlots: response.hasAvailableSlots,
      isRegistrationClosed: response.isRegistrationClosed,
      enableFaceVerification: response.enableFaceVerification,
    );
  }

  @override
  Future<MyRegistrationState> getMyRegistration({required int eventId}) async {
    try {
      final response = await _remoteDataSource.getMyRegistration(
        eventId: eventId,
      );
      final registrationStatus = RegistrationStatusParser.fromApiValue(
        response.status,
      );

      if (registrationStatus == RegistrationStatus.cancelled) {
        return const MyRegistrationState.notRegistered();
      }

      return MyRegistrationState.registered(
        MyRegistrationInfo(
          registrationId: response.registrationId,
          eventId: response.eventId,
          eventName: response.eventName,
          userId: response.userId,
          userFullName: response.userFullName,
          registerTime: response.registerTime,
          status: response.status,
          registrationStatus: registrationStatus,
          cancellationReason: response.cancellationReason,
          createdDate: response.createdDate,
        ),
      );
    } on AppError catch (error) {
      // Backend 404 tương ứng với trạng thái user chưa đăng ký event này.
      if (error.statusCode == 404) {
        return const MyRegistrationState.notRegistered();
      }
      rethrow;
    }
  }

  @override
  Future<RegisterEventResult> registerEvent({required int eventId}) async {
    final fingerprint = 'event-register:$eventId';
    final key = _getOrCreateIdempotencyKey(
      fingerprint: fingerprint,
      scope: 'event-register',
    );

    try {
      final response = await _remoteDataSource.registerEvent(
        eventId: eventId,
        idempotencyKey: key,
      );

      _clearIdempotencyKey(fingerprint);

      return RegisterEventResult(
        registrationId: response.registrationId,
        eventId: response.eventId,
        eventName: response.eventName,
        userId: response.userId,
        userFullName: response.userFullName,
        registerTime: response.registerTime,
        status: response.status,
        registrationStatus: RegistrationStatusParser.fromApiValue(
          response.status,
        ),
        cancellationReason: response.cancellationReason,
        createdDate: response.createdDate,
      );
    } on AppError catch (error) {
      if (!_shouldKeepIdempotencyKeyOnError(error)) {
        _clearIdempotencyKey(fingerprint);
      }
      rethrow;
    }
  }

  @override
  Future<CancelRegistrationResult> cancelRegistration({
    required int eventId,
    String? cancellationReason,
  }) async {
    final response = await _remoteDataSource.cancelRegistration(
      eventId: eventId,
      cancellationReason: cancellationReason,
    );

    return CancelRegistrationResult(
      registrationId: response.registrationId,
      eventId: response.eventId,
      eventName: response.eventName,
      userId: response.userId,
      userFullName: response.userFullName,
      registerTime: response.registerTime,
      status: response.status,
      registrationStatus: RegistrationStatusParser.fromApiValue(
        response.status,
      ),
      cancellationReason: response.cancellationReason,
      createdDate: response.createdDate,
    );
  }

  @override
  Future<CheckInResult> checkIn({
    required String qrToken,
    required double latitude,
    required double longitude,
    String? deviceInfo,
    String? clientDeviceId,
    String? faceImageBase64,
    String? faceImageMimeType,
    CheckInLivenessPayload? liveness,
  }) async {
    final coordinateFingerprint =
        '${latitude.toStringAsFixed(6)}:${longitude.toStringAsFixed(6)}';
    final fingerprint = 'attendance-checkin:$qrToken:$coordinateFingerprint';
    final key = _getOrCreateIdempotencyKey(
      fingerprint: fingerprint,
      scope: 'attendance-checkin',
    );

    try {
      final response = await _remoteDataSource.checkIn(
        qrToken: qrToken,
        latitude: latitude,
        longitude: longitude,
        idempotencyKey: key,
        deviceInfo: deviceInfo,
        clientDeviceId: clientDeviceId,
        faceImageBase64: faceImageBase64,
        faceImageMimeType: faceImageMimeType,
        liveness: liveness == null
            ? null
            : LivenessCheckPayloadModel(
                mode: liveness.mode,
                frameCount: liveness.frameCount,
                mimeType: liveness.mimeType,
                frames: liveness.frames
                    .map(
                      (frame) => LivenessFrameModel(
                        frameIndex: frame.frameIndex,
                        imageBase64: frame.imageBase64,
                        capturedAtMs: frame.capturedAtMs,
                      ),
                    )
                    .toList(growable: false),
              ),
      );

      _clearIdempotencyKey(fingerprint);

      return CheckInResult(
        isValid: response.isValid,
        invalidReason: response.invalidReason,
        distance: response.distance,
        pointsAwarded: response.pointsAwarded != null
            ? CheckInPointsAwarded(
                points: response.pointsAwarded!.points,
                pointType: response.pointsAwarded!.pointType,
                roleType: response.pointsAwarded!.roleType,
                currentTotalPoints: response.pointsAwarded!.currentTotalPoints,
              )
            : null,
        isSuccess: response.isSuccess,
        message: response.message,
        eventName: response.eventName,
        checkInTime: response.checkInTime,
        attendanceId: response.attendanceId,
        faceVerified: response.faceVerified,
        faceConfidence: response.faceConfidence,
        faceVerificationStatus: response.faceVerificationStatus,
        faceVerificationMessage: response.faceVerificationMessage,
        riskScore: response.riskScore,
        riskLevel: response.riskLevel,
      );
    } on AppError catch (error) {
      if (!_shouldKeepIdempotencyKeyOnError(error)) {
        _clearIdempotencyKey(fingerprint);
      }
      rethrow;
    }
  }

  @override
  Future<CheckInRequirements> getCheckInRequirements({
    required String qrToken,
  }) async {
    final response = await _remoteDataSource.getCheckInRequirements(
      qrToken: qrToken,
    );

    return CheckInRequirements(
      eventId: response.eventId,
      eventName: response.eventName,
      enableFaceVerification: response.enableFaceVerification,
    );
  }

  @override
  Future<AttendanceCheckStatus> getAttendanceCheckStatus({
    required int eventId,
  }) async {
    final response = await _remoteDataSource.getAttendanceCheckStatus(
      eventId: eventId,
    );

    return AttendanceCheckStatus(
      eventId: response.eventId,
      hasCheckedIn: response.hasCheckedIn,
      isValid: response.isValid,
      invalidReason: response.invalidReason,
    );
  }

  @override
  Future<AttendanceHistoryPageResult> getMyHistory({
    required AttendanceHistoryFilter filter,
  }) async {
    final response = await _remoteDataSource.getMyAttendanceHistory(
      pageNumber: filter.pageNumber,
      pageSize: filter.pageSize,
    );

    final items = response.items
        .map(
          (item) => AttendanceHistoryItem(
            attendanceId: item.attendanceId,
            checkInTime: item.checkInTime,
            checkInMethod: item.checkInMethod,
            isValid: item.isValid,
            invalidReason: item.invalidReason,
            distance: item.distance,
            eventName: item.eventName,
            hasAttendancePointsAwarded: item.hasAttendancePointsAwarded,
            attendancePointId: item.attendancePointId,
          ),
        )
        .toList(growable: false);

    return AttendanceHistoryPageResult(
      items: items,
      totalCount: response.totalCount,
      pageNumber: response.pageNumber,
      pageSize: response.pageSize,
      totalPages: response.totalPages,
      hasPreviousPage: response.hasPreviousPage,
      hasNextPage: response.hasNextPage,
    );
  }
}

class _IdempotencyKeyCacheEntry {
  const _IdempotencyKeyCacheEntry({required this.key, required this.createdAt});

  final String key;
  final DateTime createdAt;
}

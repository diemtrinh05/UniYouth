import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniyouth_app/core/network/idempotency_key_provider.dart';
import 'package:uniyouth_app/data/datasources/remote/events_remote_datasource.dart';
import 'package:uniyouth_app/data/models/registration/registration_result_model.dart';
import 'package:uniyouth_app/data/repositories/events_repository_impl.dart';
import 'package:uniyouth_app/domain/entities/registration/registration_status.dart';

void main() {
  group('EventsRepositoryImpl.getMyRegistration', () {
    test('maps cancelled registration to notRegistered state', () async {
      final repository = EventsRepositoryImpl(
        remoteDataSource: _FakeEventsRemoteDataSource(
          myRegistrationResult: RegistrationResultModel(
            registrationId: 88,
            eventId: 101,
            eventName: 'Event 101',
            userId: 9,
            userFullName: 'User A',
            registerTime: DateTime(2026, 3, 13, 8),
            status: '1',
            cancellationReason: 'Không tham gia được',
            createdDate: DateTime(2026, 3, 1, 10),
          ),
        ),
        idempotencyKeyProvider: const _FakeIdempotencyKeyProvider(),
      );

      final result = await repository.getMyRegistration(eventId: 101);

      expect(result.isRegistered, isFalse);
      expect(result.registration, isNull);
    });

    test(
      'maps Vietnamese cancelled registration label to notRegistered state',
      () async {
        final repository = EventsRepositoryImpl(
          remoteDataSource: _FakeEventsRemoteDataSource(
            myRegistrationResult: RegistrationResultModel(
              registrationId: 89,
              eventId: 101,
              eventName: 'Event 101',
              userId: 9,
              userFullName: 'User A',
              registerTime: DateTime(2026, 3, 13, 8),
              status: 'Đã hủy',
              cancellationReason: 'Trùng lịch',
              createdDate: DateTime(2026, 3, 1, 10),
            ),
          ),
          idempotencyKeyProvider: const _FakeIdempotencyKeyProvider(),
        );

        final result = await repository.getMyRegistration(eventId: 101);

        expect(result.isRegistered, isFalse);
        expect(result.registration, isNull);
      },
    );

    test('keeps active registration as registered state', () async {
      final repository = EventsRepositoryImpl(
        remoteDataSource: _FakeEventsRemoteDataSource(
          myRegistrationResult: RegistrationResultModel(
            registrationId: 77,
            eventId: 101,
            eventName: 'Event 101',
            userId: 9,
            userFullName: 'User A',
            registerTime: DateTime(2026, 3, 13, 8),
            status: '0',
            cancellationReason: null,
            createdDate: DateTime(2026, 3, 1, 10),
          ),
        ),
        idempotencyKeyProvider: const _FakeIdempotencyKeyProvider(),
      );

      final result = await repository.getMyRegistration(eventId: 101);

      expect(result.isRegistered, isTrue);
      expect(result.registration?.registrationId, 77);
      expect(
        result.registration?.registrationStatus,
        RegistrationStatus.registered,
      );
    });
  });
}

class _FakeEventsRemoteDataSource extends EventsRemoteDataSource {
  _FakeEventsRemoteDataSource({required this.myRegistrationResult})
    : super(dio: Dio());

  final RegistrationResultModel myRegistrationResult;

  @override
  Future<RegistrationResultModel> getMyRegistration({
    required int eventId,
  }) async {
    return myRegistrationResult;
  }
}

class _FakeIdempotencyKeyProvider implements IdempotencyKeyProvider {
  const _FakeIdempotencyKeyProvider();

  @override
  String generateKey({required String scope}) => '$scope-test-key';
}

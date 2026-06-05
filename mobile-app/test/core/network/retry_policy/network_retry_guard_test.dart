import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniyouth_app/core/error/app_error.dart';
import 'package:uniyouth_app/data/datasources/remote/base_remote_datasource.dart';

class _TestRemoteDataSource extends BaseRemoteDataSource {
  _TestRemoteDataSource() : super(Dio());

  Future<Response<dynamic>> execute(
    Future<Response<dynamic>> Function() request,
  ) {
    return runRequest<Response<dynamic>>(request);
  }
}

DioException _timeoutException({required String method, required String path}) {
  return DioException(
    requestOptions: RequestOptions(path: path, method: method),
    type: DioExceptionType.connectionTimeout,
  );
}

void main() {
  group('Retry guard for sensitive POST APIs', () {
    test('POST /api/Auth/login timeout does not retry', () async {
      final remote = _TestRemoteDataSource();
      var attempts = 0;

      await expectLater(
        () => remote.execute(() async {
          attempts += 1;
          throw _timeoutException(method: 'POST', path: '/api/Auth/login');
        }),
        throwsA(isA<AppError>()),
      );

      expect(attempts, 1);
    });

    test('POST /api/events/{id}/register timeout does not retry', () async {
      final remote = _TestRemoteDataSource();
      var attempts = 0;

      await expectLater(
        () => remote.execute(() async {
          attempts += 1;
          throw _timeoutException(
            method: 'POST',
            path: '/api/events/12/register',
          );
        }),
        throwsA(isA<AppError>()),
      );

      expect(attempts, 1);
    });

    test('POST /api/attendance/checkin timeout does not retry', () async {
      final remote = _TestRemoteDataSource();
      var attempts = 0;

      await expectLater(
        () => remote.execute(() async {
          attempts += 1;
          throw _timeoutException(
            method: 'POST',
            path: '/api/attendance/checkin',
          );
        }),
        throwsA(isA<AppError>()),
      );

      expect(attempts, 1);
    });
  });

  group('Retry guard for safe requests', () {
    test('GET request retries once when transient timeout happens', () async {
      final remote = _TestRemoteDataSource();
      var attempts = 0;

      final response = await remote.execute(() async {
        attempts += 1;
        if (attempts == 1) {
          throw _timeoutException(method: 'GET', path: '/api/Events');
        }

        return Response<dynamic>(
          requestOptions: RequestOptions(path: '/api/Events', method: 'GET'),
          statusCode: 200,
          data: <String, dynamic>{'ok': true},
        );
      });

      expect(response.statusCode, 200);
      expect(attempts, 2);
    });
  });
}

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uniyouth_app/data/datasources/remote/auth_remote_datasource.dart';

void main() {
  group('AuthRemoteDataSource fallback success messages', () {
    test(
      'forgotPassword returns Vietnamese fallback when backend omits message',
      () async {
        final datasource = AuthRemoteDataSource(
          dio: _buildDioReturning(<String, dynamic>{
            'success': true,
            'data': null,
          }),
        );

        final message = await datasource.forgotPassword(account: 'SV2001');

        expect(
          message,
          'Nếu tài khoản hợp lệ, mã OTP đặt lại mật khẩu đã được gửi.',
        );
      },
    );

    test(
      'resetPassword returns Vietnamese fallback when backend omits message',
      () async {
        final datasource = AuthRemoteDataSource(
          dio: _buildDioReturning(<String, dynamic>{
            'success': true,
            'data': null,
          }),
        );

        final message = await datasource.resetPassword(
          verificationTicket: 'verification-ticket',
          newPassword: 'NewPass@123',
        );

        expect(message, 'Đặt lại mật khẩu thành công.');
      },
    );
  });

  group('AuthRemoteDataSource reset password contract', () {
    test('resetPassword sends verificationTicket and does not send token', () async {
      Map<String, dynamic>? capturedRequestData;
      final datasource = AuthRemoteDataSource(
        dio: _buildDioReturning(
          <String, dynamic>{
            'success': true,
            'message': 'Đặt lại mật khẩu thành công.',
          },
          onRequestData: (data) {
            if (data is Map) {
              capturedRequestData = data.map(
                (key, value) => MapEntry(key.toString(), value),
              );
            }
          },
        ),
      );

      await datasource.resetPassword(
        verificationTicket: ' verification-ticket ',
        newPassword: 'NewPass@123',
      );

      expect(capturedRequestData, isNotNull);
      expect(
        capturedRequestData,
        containsPair('verificationTicket', 'verification-ticket'),
      );
      expect(
        capturedRequestData,
        containsPair('newPassword', 'NewPass@123'),
      );
      expect(capturedRequestData, isNot(contains('token')));
    });
  });
}

Dio _buildDioReturning(
  Map<String, dynamic> responseData, {
  void Function(Object? data)? onRequestData,
}) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        onRequestData?.call(options.data);
        handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            statusCode: 200,
            data: responseData,
          ),
        );
      },
    ),
  );
  return dio;
}

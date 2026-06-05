import 'package:dio/dio.dart';

import '../../models/auth/forgot_password_request_model.dart';
import '../../models/auth/login_request_model.dart';
import '../../models/auth/login_response_model.dart';
import '../../models/auth/reset_password_request_model.dart';
import '../../models/auth/verify_reset_otp_request_model.dart';
import '../../models/auth/verify_reset_otp_response_model.dart';
import 'base_remote_datasource.dart';

class AuthRemoteDataSource extends BaseRemoteDataSource {
  AuthRemoteDataSource({required Dio dio}) : super(dio);

  static const String _forgotPasswordFallbackMessage =
      'Nếu tài khoản hợp lệ, mã OTP đặt lại mật khẩu đã được gửi.';
  static const String _resetPasswordFallbackMessage =
      'Đặt lại mật khẩu thành công.';

  Future<bool> checkHealth() async {
    final response = await runRequest(
      () => dio.get<dynamic>('/api/Auth/health'),
    );

    final body = response.data;
    if (body is! Map) {
      return true;
    }

    final typedBody = body.map((key, value) => MapEntry(key.toString(), value));
    final rawSuccess = typedBody['success'];
    if (rawSuccess is bool) {
      return rawSuccess;
    }
    if (rawSuccess is String) {
      final normalized = rawSuccess.trim().toLowerCase();
      if (normalized == 'true') {
        return true;
      }
      if (normalized == 'false') {
        return false;
      }
    }

    return true;
  }

  Future<LoginResponseModel> login({
    required String code,
    required String password,
  }) async {
    final response = await runRequest(
      () => dio.post<dynamic>(
        '/api/Auth/login',
        data: LoginRequestModel(
          code: code,
          password: password,
        ).toJson(),
      ),
    );

    final body = response.data;
    if (body is! Map) {
      throw const FormatException('Invalid login response body.');
    }

    final typedBody = body.map((key, value) => MapEntry(key.toString(), value));
    return LoginResponseModel.fromApiResponse(typedBody);
  }

  Future<LoginResponseModel> refreshToken({
    required String refreshToken,
  }) async {
    final response = await runRequest(
      () => dio.post<dynamic>(
        '/api/Auth/refresh',
        data: <String, dynamic>{
          'refreshToken': refreshToken,
        },
        options: Options(
          extra: const <String, Object>{
            'skipAuthorization': true,
            'skipAuthRefresh': true,
          },
        ),
      ),
    );

    final body = response.data;
    if (body is! Map) {
      throw const FormatException('Invalid refresh token response body.');
    }

    final typedBody = body.map((key, value) => MapEntry(key.toString(), value));
    return LoginResponseModel.fromApiResponse(typedBody);
  }

  Future<void> revokeToken({
    required String refreshToken,
  }) async {
    await runRequest(
      () => dio.post<dynamic>(
        '/api/Auth/revoke',
        data: <String, dynamic>{
          'refreshToken': refreshToken,
        },
        options: Options(
          extra: const <String, Object>{
            'skipAuthorization': true,
            'skipAuthRefresh': true,
          },
        ),
      ),
    );
  }

  Future<String> forgotPassword({required String account}) async {
    final response = await runRequest(
      () => dio.post<dynamic>(
        '/api/Auth/forgot-password',
        data: ForgotPasswordRequestModel(account: account).toJson(),
      ),
    );

    return _extractMessage(
      response.data,
      fallbackMessage: _forgotPasswordFallbackMessage,
    );
  }

  Future<VerifyResetOtpResponseModel> verifyResetOtp({
    required String account,
    required String otpCode,
  }) async {
    final response = await runRequest(
      () => dio.post<dynamic>(
        '/api/Auth/verify-reset-otp',
        data: VerifyResetOtpRequestModel(
          account: account,
          otpCode: otpCode,
        ).toJson(),
      ),
    );

    final body = response.data;
    if (body is! Map) {
      throw const FormatException('Invalid verify reset OTP response body.');
    }

    final typedBody = body.map((key, value) => MapEntry(key.toString(), value));
    return VerifyResetOtpResponseModel.fromApiResponse(typedBody);
  }

  Future<String> resetPassword({
    required String verificationTicket,
    required String newPassword,
  }) async {
    final normalizedVerificationTicket = verificationTicket.trim();
    if (normalizedVerificationTicket.isEmpty) {
      throw ArgumentError('verificationTicket is required for reset password.');
    }

    final response = await runRequest(
      () => dio.post<dynamic>(
        '/api/Auth/reset-password',
        data: ResetPasswordRequestModel(
          verificationTicket: normalizedVerificationTicket,
          newPassword: newPassword,
        ).toJson(),
      ),
    );

    return _extractMessage(
      response.data,
      fallbackMessage: _resetPasswordFallbackMessage,
    );
  }

  String _extractMessage(Object? data, {required String fallbackMessage}) {
    if (data is! Map) {
      return fallbackMessage;
    }

    final typedData = data.map((key, value) => MapEntry(key.toString(), value));
    final message = typedData['message']?.toString();
    if (message != null && message.trim().isNotEmpty) {
      return message;
    }

    return fallbackMessage;
  }
}


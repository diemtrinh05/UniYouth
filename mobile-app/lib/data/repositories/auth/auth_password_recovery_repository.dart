import '../../../domain/usecases/auth/forgot_password_usecase.dart';
import '../../../domain/usecases/auth/reset_password_usecase.dart';
import '../../../domain/usecases/auth/verify_reset_otp_usecase.dart';
import '../../datasources/remote/auth_remote_datasource.dart';

class AuthPasswordRecoveryRepository
    implements
        ForgotPasswordRepository,
        ResetPasswordRepository,
        VerifyResetOtpRepository {
  AuthPasswordRecoveryRepository({
    required AuthRemoteDataSource authRemoteDataSource,
  }) : _authRemoteDataSource = authRemoteDataSource;

  final AuthRemoteDataSource _authRemoteDataSource;

  @override
  Future<String> forgotPassword({
    required String account,
  }) {
    return _authRemoteDataSource.forgotPassword(account: account);
  }

  @override
  Future<String> resetPassword({
    required String verificationTicket,
    required String newPassword,
  }) {
    return _authRemoteDataSource.resetPassword(
      verificationTicket: verificationTicket,
      newPassword: newPassword,
    );
  }

  @override
  Future<VerifyResetOtpResult> verifyResetOtp({
    required String account,
    required String otpCode,
  }) async {
    final result = await _authRemoteDataSource.verifyResetOtp(
      account: account,
      otpCode: otpCode,
    );

    return VerifyResetOtpResult(
      message: result.message,
      verificationTicket: result.verificationTicket,
      expiresAt: result.expiresAt,
    );
  }
}

import 'package:flutter_riverpod/legacy.dart';

import '../../../../../../core/error/app_error.dart';
import '../../../../../../core/error/error_presenter.dart';
import '../../../../../../domain/usecases/profile/delete_avatar_usecase.dart';
import '../../../../../../domain/usecases/profile/enroll_face_profile_usecase.dart';
import '../../../../../../domain/usecases/profile/get_my_profile_usecase.dart';
import '../../../../../../domain/usecases/profile/request_face_profile_reauth_otp_usecase.dart';
import '../../../../../../domain/usecases/profile/upload_avatar_usecase.dart';
import '../../../attendance/face_capture/attendance_face_capture_service.dart';
import '../../avatar/avatar_picker_service.dart';
import 'profile_view_state.dart';

class ProfileViewNotifier extends StateNotifier<ProfileViewState> {
  ProfileViewNotifier({
    required GetMyProfileUseCase getMyProfileUseCase,
    required UploadAvatarUseCase uploadAvatarUseCase,
    required DeleteAvatarUseCase deleteAvatarUseCase,
    required EnrollFaceProfileUseCase enrollFaceProfileUseCase,
    required RequestFaceProfileReauthOtpUseCase requestFaceProfileReauthOtpUseCase,
    required AvatarPickerService avatarPickerService,
  }) : _getMyProfileUseCase = getMyProfileUseCase,
       _uploadAvatarUseCase = uploadAvatarUseCase,
       _deleteAvatarUseCase = deleteAvatarUseCase,
       _enrollFaceProfileUseCase = enrollFaceProfileUseCase,
       _requestFaceProfileReauthOtpUseCase = requestFaceProfileReauthOtpUseCase,
       _avatarPickerService = avatarPickerService,
       super(const ProfileViewState());

  final GetMyProfileUseCase _getMyProfileUseCase;
  final UploadAvatarUseCase _uploadAvatarUseCase;
  final DeleteAvatarUseCase _deleteAvatarUseCase;
  final EnrollFaceProfileUseCase _enrollFaceProfileUseCase;
  final RequestFaceProfileReauthOtpUseCase _requestFaceProfileReauthOtpUseCase;
  final AvatarPickerService _avatarPickerService;
  bool _isDisposed = false;

  Future<void> syncInitial() async {
    _setState(state.copyWith(isLoading: true, clearErrorMessage: true));

    try {
      final result = await _getMyProfileUseCase();
      _setState(state.copyWith(profile: result, isLoading: false));
    } on AppError catch (error) {
      _setState(
        state.copyWith(
          isLoading: false,
          errorMessage: ErrorPresenter.presentAppError(
            error,
            operation: 'tải hồ sơ cá nhân',
          ).message,
        ),
      );
    } on FormatException catch (_) {
      _setState(
        state.copyWith(
          isLoading: false,
          errorMessage: ErrorPresenter.presentException(
            operation: 'tải hồ sơ cá nhân',
          ).message,
        ),
      );
    }
  }

  Future<void> refresh() => syncInitial();

  Future<void> uploadAvatar() async {
    if (state.isUploadingAvatar) {
      return;
    }

    final pickedFile = await _avatarPickerService.pickAvatarFile();
    if (pickedFile == null) {
      return;
    }

    _setState(state.copyWith(isUploadingAvatar: true));
    try {
      final result = await _uploadAvatarUseCase(file: pickedFile);
      final message = (result.message ?? '').trim();
      if (message.isNotEmpty) {
        _setState(state.copyWith(feedbackMessage: message));
      }
      await syncInitial();
    } on AppError catch (error) {
      _setState(
        state.copyWith(
          feedbackMessage: error.statusCode == 400
              ? 'File avatar không hợp lệ (JPG/PNG/WEBP, tối đa 2MB).'
              : ErrorPresenter.presentAppError(
                  error,
                  operation: 'tải lên avatar',
                ).message,
        ),
      );
    } on FormatException catch (_) {
      _setState(
        state.copyWith(
          feedbackMessage: ErrorPresenter.presentException(
            operation: 'tải lên avatar',
          ).message,
        ),
      );
    } finally {
      _setState(state.copyWith(isUploadingAvatar: false));
    }
  }

  Future<void> deleteAvatar() async {
    if (state.isDeletingAvatar) {
      return;
    }

    _setState(state.copyWith(isDeletingAvatar: true));
    try {
      await _deleteAvatarUseCase();
      _setState(state.copyWith(feedbackMessage: 'Xóa avatar thành công'));
      await syncInitial();
    } on AppError catch (error) {
      _setState(
        state.copyWith(
          feedbackMessage: ErrorPresenter.presentAppError(
            error,
            operation: 'xóa avatar',
          ).message,
        ),
      );
    } on FormatException catch (_) {
      _setState(
        state.copyWith(
          feedbackMessage: ErrorPresenter.presentException(
            operation: 'xóa avatar',
          ).message,
        ),
      );
    } finally {
      _setState(state.copyWith(isDeletingAvatar: false));
    }
  }

  Future<void> enrollFaceProfile({
    required CapturedFaceImage faceImage,
    String? reauthOtpCode,
  }) async {
    if (state.isEnrollingFace) {
      return;
    }

    _setState(state.copyWith(isEnrollingFace: true));
    try {
      final result = await _enrollFaceProfileUseCase(
        input: EnrollFaceProfileInput(
          imageBytes: faceImage.bytes,
          imageMimeType: faceImage.mimeType,
          reauthOtpCode: reauthOtpCode,
        ),
      );
      final message = (result.message ?? '').trim();
      if (message.isNotEmpty) {
        _setState(state.copyWith(feedbackMessage: message));
      }
      await syncInitial();
    } on AppError catch (error) {
      _setState(
        state.copyWith(
          feedbackMessage: ErrorPresenter.presentAppError(
            error,
            operation: 'đăng ký khuôn mặt',
          ).message,
        ),
      );
    } on FormatException catch (_) {
      _setState(
        state.copyWith(
          feedbackMessage: ErrorPresenter.presentException(
            operation: 'đăng ký khuôn mặt',
          ).message,
        ),
      );
    } finally {
      _setState(state.copyWith(isEnrollingFace: false));
    }
  }

  Future<bool> requestFaceProfileReauthOtp() async {
    try {
      final result = await _requestFaceProfileReauthOtpUseCase();
      final message = (result.message ?? '').trim();
      if (message.isNotEmpty) {
        _setState(state.copyWith(feedbackMessage: message));
      }
      return true;
    } on AppError catch (error) {
      _setState(
        state.copyWith(
          feedbackMessage: ErrorPresenter.presentAppError(
            error,
            operation: 'gửi mã OTP cập nhật khuôn mặt',
          ).message,
        ),
      );
      return false;
    } on FormatException catch (_) {
      _setState(
        state.copyWith(
          feedbackMessage: ErrorPresenter.presentException(
            operation: 'gửi mã OTP cập nhật khuôn mặt',
          ).message,
        ),
      );
      return false;
    }
  }

  void clearFeedbackMessage() {
    if (state.feedbackMessage == null) {
      return;
    }
    _setState(state.copyWith(clearFeedbackMessage: true));
  }

  void _setState(ProfileViewState nextState) {
    if (_isDisposed) {
      return;
    }
    state = nextState;
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:uniyouth_app/domain/usecases/profile/delete_avatar_usecase.dart';
import 'package:uniyouth_app/domain/usecases/profile/enroll_face_profile_usecase.dart';
import 'package:uniyouth_app/domain/usecases/profile/get_my_profile_usecase.dart';
import 'package:uniyouth_app/domain/usecases/profile/request_face_profile_reauth_otp_usecase.dart';
import 'package:uniyouth_app/domain/usecases/profile/upload_avatar_usecase.dart';
import 'package:uniyouth_app/presentation/features/attendance/face_capture/attendance_face_capture_service.dart';
import 'package:uniyouth_app/presentation/features/profile/avatar/avatar_picker_service.dart';
import 'package:uniyouth_app/presentation/features/profile/profile_view/state/profile_view_notifier.dart';

void main() {
  group('ProfileViewNotifier', () {
    test('syncInitial loads profile data', () async {
      final getProfileRepository = _FakeGetMyProfileRepository();
      final notifier = ProfileViewNotifier(
        getMyProfileUseCase: GetMyProfileUseCase(
          repository: getProfileRepository,
        ),
        uploadAvatarUseCase: UploadAvatarUseCase(
          repository: _FakeUploadAvatarRepository(),
        ),
        deleteAvatarUseCase: DeleteAvatarUseCase(
          repository: _FakeDeleteAvatarRepository(),
        ),
        enrollFaceProfileUseCase: EnrollFaceProfileUseCase(
          repository: _FakeEnrollFaceProfileRepository(),
        ),
        requestFaceProfileReauthOtpUseCase: RequestFaceProfileReauthOtpUseCase(
          repository: _FakeRequestFaceProfileReauthOtpRepository(),
        ),
        avatarPickerService: _FakeAvatarPickerService(),
      );
      addTearDown(notifier.dispose);

      await notifier.syncInitial();

      expect(getProfileRepository.callCount, 1);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.profile?.fullName, 'Nguyen Van A');
      expect(notifier.state.errorMessage, isNull);
    });

    test('uploadAvatar sets feedback message and refreshes profile', () async {
      final getProfileRepository = _FakeGetMyProfileRepository();
      final uploadRepository = _FakeUploadAvatarRepository()
        ..onUploadAvatar = ({required file}) async {
          return const UploadAvatarResult(
            avatarUrl: 'https://cdn/avatar-new.png',
            message: 'Cập nhật ảnh đại diện thành công',
          );
        };
      final notifier = ProfileViewNotifier(
        getMyProfileUseCase: GetMyProfileUseCase(
          repository: getProfileRepository,
        ),
        uploadAvatarUseCase: UploadAvatarUseCase(repository: uploadRepository),
        deleteAvatarUseCase: DeleteAvatarUseCase(
          repository: _FakeDeleteAvatarRepository(),
        ),
        enrollFaceProfileUseCase: EnrollFaceProfileUseCase(
          repository: _FakeEnrollFaceProfileRepository(),
        ),
        requestFaceProfileReauthOtpUseCase: RequestFaceProfileReauthOtpUseCase(
          repository: _FakeRequestFaceProfileReauthOtpRepository(),
        ),
        avatarPickerService: _FakeAvatarPickerService(
          file: const UploadAvatarFile(
            fileName: 'avatar.png',
            bytes: <int>[1, 2, 3],
          ),
        ),
      );
      addTearDown(notifier.dispose);

      await notifier.uploadAvatar();

      expect(uploadRepository.callCount, 1);
      expect(getProfileRepository.callCount, 1);
      expect(
        notifier.state.feedbackMessage,
        'Cập nhật ảnh đại diện thành công',
      );
      expect(notifier.state.isUploadingAvatar, isFalse);
    });

    test(
      'enrollFaceProfile sets feedback message and refreshes profile',
      () async {
        final getProfileRepository = _FakeGetMyProfileRepository();
        final enrollRepository = _FakeEnrollFaceProfileRepository()
          ..onEnrollFaceProfile = ({required input}) async {
            return const EnrollFaceProfileResult(
              imageUrl: 'https://cdn/face-profile.jpg',
              message: 'Đăng ký khuôn mặt thành công',
              qualityScore: 0.91,
            );
          };
        final notifier = ProfileViewNotifier(
          getMyProfileUseCase: GetMyProfileUseCase(
            repository: getProfileRepository,
          ),
          uploadAvatarUseCase: UploadAvatarUseCase(
            repository: _FakeUploadAvatarRepository(),
          ),
          deleteAvatarUseCase: DeleteAvatarUseCase(
            repository: _FakeDeleteAvatarRepository(),
          ),
          enrollFaceProfileUseCase: EnrollFaceProfileUseCase(
            repository: enrollRepository,
          ),
          requestFaceProfileReauthOtpUseCase:
              RequestFaceProfileReauthOtpUseCase(
                repository: _FakeRequestFaceProfileReauthOtpRepository(),
              ),
          avatarPickerService: _FakeAvatarPickerService(),
        );
        addTearDown(notifier.dispose);

        await notifier.enrollFaceProfile(
          faceImage: const CapturedFaceImage(
            bytes: <int>[1, 2, 3],
            mimeType: 'image/jpeg',
            fileName: 'face.jpg',
          ),
        );

        expect(enrollRepository.callCount, 1);
        expect(getProfileRepository.callCount, 1);
        expect(notifier.state.feedbackMessage, 'Đăng ký khuôn mặt thành công');
        expect(notifier.state.isEnrollingFace, isFalse);
      },
    );
  });
}

class _FakeGetMyProfileRepository implements GetMyProfileRepository {
  int callCount = 0;

  @override
  Future<MyProfile> getMyProfile() async {
    callCount += 1;
    return _profile();
  }
}

class _FakeUploadAvatarRepository implements UploadAvatarRepository {
  int callCount = 0;
  UploadAvatarFile? lastFile;

  Future<UploadAvatarResult> Function({required UploadAvatarFile file})?
  onUploadAvatar;

  @override
  Future<UploadAvatarResult> uploadAvatar({
    required UploadAvatarFile file,
  }) async {
    callCount += 1;
    lastFile = file;
    final override = onUploadAvatar;
    if (override != null) {
      return override(file: file);
    }
    return const UploadAvatarResult(avatarUrl: null, message: null);
  }
}

class _FakeRequestFaceProfileReauthOtpRepository
    implements RequestFaceProfileReauthOtpRepository {
  @override
  Future<RequestFaceProfileReauthOtpResult>
  requestFaceProfileReauthOtp() async {
    return const RequestFaceProfileReauthOtpResult(
      message: 'OTP sent successfully',
    );
  }
}

class _FakeDeleteAvatarRepository implements DeleteAvatarRepository {
  @override
  Future<void> deleteAvatar() async {}
}

class _FakeEnrollFaceProfileRepository implements EnrollFaceProfileRepository {
  int callCount = 0;
  EnrollFaceProfileInput? lastInput;

  Future<EnrollFaceProfileResult> Function({
    required EnrollFaceProfileInput input,
  })?
  onEnrollFaceProfile;

  @override
  Future<EnrollFaceProfileResult> enrollFaceProfile({
    required EnrollFaceProfileInput input,
  }) async {
    callCount += 1;
    lastInput = input;
    final override = onEnrollFaceProfile;
    if (override != null) {
      return override(input: input);
    }

    return const EnrollFaceProfileResult(
      imageUrl: null,
      message: null,
      qualityScore: null,
    );
  }
}

class _FakeAvatarPickerService implements AvatarPickerService {
  _FakeAvatarPickerService({this.file});

  final UploadAvatarFile? file;

  @override
  Future<UploadAvatarFile?> pickAvatarFile() async => file;
}

MyProfile _profile() {
  return MyProfile(
    userId: 1,
    code: 'SV001',
    fullName: 'Nguyen Van A',
    email: 'a@example.com',
    phone: '0900000000',
    avatarUrl: 'https://cdn/avatar.png',
    gender: true,
    dateOfBirth: DateTime(2000, 1, 1),
    address: 'HCM',
    role: 'Student',
    unitName: 'Unit',
    unitId: 10,
    positionId: 3,
    joinDate: DateTime(2024, 1, 1),
    position: 'Member',
    instituteName: 'Institute',
    instituteId: 20,
    status: 1,
    lastLoginDate: DateTime(2026, 1, 1),
    createdDate: DateTime(2024, 1, 1),
  );
}

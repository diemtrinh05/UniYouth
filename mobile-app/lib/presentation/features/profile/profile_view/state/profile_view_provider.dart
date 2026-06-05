import 'package:flutter_riverpod/legacy.dart';

import '../../../../../../domain/usecases/profile/delete_avatar_usecase.dart';
import '../../../../../../domain/usecases/profile/enroll_face_profile_usecase.dart';
import '../../../../../../domain/usecases/profile/get_my_profile_usecase.dart';
import '../../../../../../domain/usecases/profile/request_face_profile_reauth_otp_usecase.dart';
import '../../../../../../domain/usecases/profile/upload_avatar_usecase.dart';
import '../../../attendance/face_capture/attendance_face_capture_service.dart';
import '../../avatar/avatar_picker_service.dart';
import 'profile_view_notifier.dart';
import 'profile_view_state.dart';

class ProfileViewNotifierDependencies {
  const ProfileViewNotifierDependencies({
    required this.getMyProfileUseCase,
    required this.uploadAvatarUseCase,
    required this.deleteAvatarUseCase,
    required this.enrollFaceProfileUseCase,
    required this.requestFaceProfileReauthOtpUseCase,
    required this.avatarPickerService,
    required this.faceCaptureService,
  });

  final GetMyProfileUseCase getMyProfileUseCase;
  final UploadAvatarUseCase uploadAvatarUseCase;
  final DeleteAvatarUseCase deleteAvatarUseCase;
  final EnrollFaceProfileUseCase enrollFaceProfileUseCase;
  final RequestFaceProfileReauthOtpUseCase requestFaceProfileReauthOtpUseCase;
  final AvatarPickerService avatarPickerService;
  final AttendanceFaceCaptureService faceCaptureService;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is ProfileViewNotifierDependencies &&
        other.getMyProfileUseCase == getMyProfileUseCase &&
        other.uploadAvatarUseCase == uploadAvatarUseCase &&
        other.deleteAvatarUseCase == deleteAvatarUseCase &&
        other.enrollFaceProfileUseCase == enrollFaceProfileUseCase &&
        other.requestFaceProfileReauthOtpUseCase == requestFaceProfileReauthOtpUseCase &&
        other.avatarPickerService == avatarPickerService &&
        other.faceCaptureService == faceCaptureService;
  }

  @override
  int get hashCode {
    return Object.hash(
      getMyProfileUseCase,
      uploadAvatarUseCase,
      deleteAvatarUseCase,
      enrollFaceProfileUseCase,
      requestFaceProfileReauthOtpUseCase,
      avatarPickerService,
      faceCaptureService,
    );
  }
}

final profileViewNotifierByDependenciesProvider = StateNotifierProvider
    .autoDispose
    .family<
      ProfileViewNotifier,
      ProfileViewState,
      ProfileViewNotifierDependencies
    >((ref, dependencies) {
      return ProfileViewNotifier(
        getMyProfileUseCase: dependencies.getMyProfileUseCase,
        uploadAvatarUseCase: dependencies.uploadAvatarUseCase,
        deleteAvatarUseCase: dependencies.deleteAvatarUseCase,
        enrollFaceProfileUseCase: dependencies.enrollFaceProfileUseCase,
        requestFaceProfileReauthOtpUseCase: dependencies.requestFaceProfileReauthOtpUseCase,
        avatarPickerService: dependencies.avatarPickerService,
      );
    });

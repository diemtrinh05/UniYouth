import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/profile/profile_repository_impl.dart';
import '../../../domain/usecases/profile/change_password_usecase.dart';
import '../../../domain/usecases/profile/delete_avatar_usecase.dart';
import '../../../domain/usecases/profile/enroll_face_profile_usecase.dart';
import '../../../domain/usecases/profile/get_my_profile_usecase.dart';
import '../../../domain/usecases/profile/get_position_options_usecase.dart';
import '../../../domain/usecases/profile/request_face_profile_reauth_otp_usecase.dart';
import '../../../domain/usecases/profile/update_my_profile_usecase.dart';
import '../../../domain/usecases/profile/upload_avatar_usecase.dart';
import 'app_foundation_providers.dart';

final profileRepositoryProvider = Provider<ProfileRepositoryImpl>(
  (ref) => ProfileRepositoryImpl(
    usersRemoteDataSource: ref.watch(usersRemoteDataSourceProvider),
  ),
);

final changePasswordUseCaseProvider = Provider<ChangePasswordUseCase>(
  (ref) =>
      ChangePasswordUseCase(repository: ref.watch(profileRepositoryProvider)),
);

final getMyProfileUseCaseProvider = Provider<GetMyProfileUseCase>(
  (ref) =>
      GetMyProfileUseCase(repository: ref.watch(profileRepositoryProvider)),
);

final getPositionOptionsUseCaseProvider = Provider<GetPositionOptionsUseCase>(
  (ref) => GetPositionOptionsUseCase(
    repository: ref.watch(profileRepositoryProvider),
  ),
);

final updateMyProfileUseCaseProvider = Provider<UpdateMyProfileUseCase>(
  (ref) =>
      UpdateMyProfileUseCase(repository: ref.watch(profileRepositoryProvider)),
);

final uploadAvatarUseCaseProvider = Provider<UploadAvatarUseCase>(
  (ref) =>
      UploadAvatarUseCase(repository: ref.watch(profileRepositoryProvider)),
);

final deleteAvatarUseCaseProvider = Provider<DeleteAvatarUseCase>(
  (ref) =>
      DeleteAvatarUseCase(repository: ref.watch(profileRepositoryProvider)),
);

final enrollFaceProfileUseCaseProvider = Provider<EnrollFaceProfileUseCase>(
  (ref) => EnrollFaceProfileUseCase(
    repository: ref.watch(profileRepositoryProvider),
  ),
);

final requestFaceProfileReauthOtpUseCaseProvider =
    Provider<RequestFaceProfileReauthOtpUseCase>(
      (ref) => RequestFaceProfileReauthOtpUseCase(
        repository: ref.watch(profileRepositoryProvider),
      ),
    );

class ProfileNavigationBindings {
  const ProfileNavigationBindings({
    required this.changePasswordUseCase,
    required this.getMyProfileUseCase,
    required this.getPositionOptionsUseCase,
    required this.updateMyProfileUseCase,
    required this.uploadAvatarUseCase,
    required this.deleteAvatarUseCase,
    required this.enrollFaceProfileUseCase,
    required this.requestFaceProfileReauthOtpUseCase,
  });

  final ChangePasswordUseCase Function() changePasswordUseCase;
  final GetMyProfileUseCase Function() getMyProfileUseCase;
  final GetPositionOptionsUseCase Function() getPositionOptionsUseCase;
  final UpdateMyProfileUseCase Function() updateMyProfileUseCase;
  final UploadAvatarUseCase Function() uploadAvatarUseCase;
  final DeleteAvatarUseCase Function() deleteAvatarUseCase;
  final EnrollFaceProfileUseCase Function() enrollFaceProfileUseCase;
  final RequestFaceProfileReauthOtpUseCase Function()
  requestFaceProfileReauthOtpUseCase;
}

final profileNavigationBindingsProvider = Provider<ProfileNavigationBindings>((
  ref,
) {
  final read = ref.read;
  return ProfileNavigationBindings(
    changePasswordUseCase: () => read(changePasswordUseCaseProvider),
    getMyProfileUseCase: () => read(getMyProfileUseCaseProvider),
    getPositionOptionsUseCase: () => read(getPositionOptionsUseCaseProvider),
    updateMyProfileUseCase: () => read(updateMyProfileUseCaseProvider),
    uploadAvatarUseCase: () => read(uploadAvatarUseCaseProvider),
    deleteAvatarUseCase: () => read(deleteAvatarUseCaseProvider),
    enrollFaceProfileUseCase: () => read(enrollFaceProfileUseCaseProvider),
    requestFaceProfileReauthOtpUseCase: () =>
        read(requestFaceProfileReauthOtpUseCaseProvider),
  );
});

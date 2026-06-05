import 'package:flutter_riverpod/legacy.dart';

import '../../../../../../domain/usecases/profile/get_my_profile_usecase.dart';
import '../../../../../../domain/usecases/profile/update_my_profile_usecase.dart';
import 'profile_edit_notifier.dart';
import 'profile_edit_state.dart';

class ProfileEditNotifierDependencies {
  const ProfileEditNotifierDependencies({
    required this.initialProfile,
    required this.updateMyProfileUseCase,
  });

  final MyProfile initialProfile;
  final UpdateMyProfileUseCase updateMyProfileUseCase;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is ProfileEditNotifierDependencies &&
        other.initialProfile == initialProfile &&
        other.updateMyProfileUseCase == updateMyProfileUseCase;
  }

  @override
  int get hashCode => Object.hash(initialProfile, updateMyProfileUseCase);
}

final profileEditNotifierByDependenciesProvider = StateNotifierProvider
    .autoDispose
    .family<
      ProfileEditNotifier,
      ProfileEditState,
      ProfileEditNotifierDependencies
    >((ref, dependencies) {
      return ProfileEditNotifier(
        initialProfile: dependencies.initialProfile,
        updateMyProfileUseCase: dependencies.updateMyProfileUseCase,
      );
    });

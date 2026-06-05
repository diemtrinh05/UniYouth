import 'package:flutter_riverpod/legacy.dart';

import '../../../../../../domain/usecases/profile/change_password_usecase.dart';
import 'change_password_notifier.dart';
import 'change_password_state.dart';

class ChangePasswordNotifierDependencies {
  const ChangePasswordNotifierDependencies({
    required this.changePasswordUseCase,
  });

  final ChangePasswordUseCase changePasswordUseCase;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is ChangePasswordNotifierDependencies &&
        other.changePasswordUseCase == changePasswordUseCase;
  }

  @override
  int get hashCode => changePasswordUseCase.hashCode;
}

final changePasswordNotifierByDependenciesProvider = StateNotifierProvider
    .autoDispose
    .family<
      ChangePasswordNotifier,
      ChangePasswordState,
      ChangePasswordNotifierDependencies
    >((ref, dependencies) {
      return ChangePasswordNotifier(
        changePasswordUseCase: dependencies.changePasswordUseCase,
      );
    });

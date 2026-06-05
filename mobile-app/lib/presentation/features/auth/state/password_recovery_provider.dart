import 'package:flutter_riverpod/legacy.dart';

import '../../../../domain/usecases/auth/forgot_password_usecase.dart';
import '../../../../domain/usecases/auth/reset_password_usecase.dart';
import '../../../app/providers/app_provider_graph.dart';
import 'forgot_password_notifier.dart';
import 'forgot_password_state.dart';
import 'reset_password_notifier.dart';
import 'reset_password_state.dart';

class ForgotPasswordNotifierDependencies {
  const ForgotPasswordNotifierDependencies({
    required this.forgotPasswordUseCase,
  });

  final ForgotPasswordUseCase forgotPasswordUseCase;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is ForgotPasswordNotifierDependencies &&
        other.forgotPasswordUseCase == forgotPasswordUseCase;
  }

  @override
  int get hashCode => forgotPasswordUseCase.hashCode;
}

class ResetPasswordNotifierDependencies {
  const ResetPasswordNotifierDependencies({required this.resetPasswordUseCase});

  final ResetPasswordUseCase resetPasswordUseCase;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is ResetPasswordNotifierDependencies &&
        other.resetPasswordUseCase == resetPasswordUseCase;
  }

  @override
  int get hashCode => resetPasswordUseCase.hashCode;
}

final forgotPasswordNotifierProvider =
    StateNotifierProvider.autoDispose<
      ForgotPasswordNotifier,
      ForgotPasswordState
    >((ref) {
      return ForgotPasswordNotifier(
        forgotPasswordUseCase: ref.watch(forgotPasswordUseCaseProvider),
      );
    });

final forgotPasswordNotifierByDependenciesProvider = StateNotifierProvider
    .autoDispose
    .family<
      ForgotPasswordNotifier,
      ForgotPasswordState,
      ForgotPasswordNotifierDependencies
    >((ref, dependencies) {
      return ForgotPasswordNotifier(
        forgotPasswordUseCase: dependencies.forgotPasswordUseCase,
      );
    });

final resetPasswordNotifierProvider =
    StateNotifierProvider.autoDispose<
      ResetPasswordNotifier,
      ResetPasswordState
    >((ref) {
      return ResetPasswordNotifier(
        resetPasswordUseCase: ref.watch(resetPasswordUseCaseProvider),
      );
    });

final resetPasswordNotifierByDependenciesProvider = StateNotifierProvider
    .autoDispose
    .family<
      ResetPasswordNotifier,
      ResetPasswordState,
      ResetPasswordNotifierDependencies
    >((ref, dependencies) {
      return ResetPasswordNotifier(
        resetPasswordUseCase: dependencies.resetPasswordUseCase,
      );
    });

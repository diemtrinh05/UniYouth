import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../app/providers/app_provider_graph.dart';
import '../../../../domain/usecases/auth/login_usecase.dart';
import 'auth_notifier.dart';
import 'auth_state.dart';

class AuthNotifierDependencies {
  const AuthNotifierDependencies({
    required this.loginUseCase,
    required this.onAuthenticatedTokenSync,
    required this.consumeNotificationPermissionDeniedHint,
  });

  final LoginUseCase loginUseCase;
  final AuthenticatedTokenSync onAuthenticatedTokenSync;
  final ConsumeNotificationPermissionDeniedHint
  consumeNotificationPermissionDeniedHint;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is AuthNotifierDependencies &&
        other.loginUseCase == loginUseCase &&
        other.onAuthenticatedTokenSync == onAuthenticatedTokenSync &&
        other.consumeNotificationPermissionDeniedHint ==
            consumeNotificationPermissionDeniedHint;
  }

  @override
  int get hashCode {
    return Object.hash(
      loginUseCase,
      onAuthenticatedTokenSync,
      consumeNotificationPermissionDeniedHint,
    );
  }
}

final authOnAuthenticatedTokenSyncProvider = Provider<AuthenticatedTokenSync>((
  ref,
) {
  return () async => false;
});

final authConsumeNotificationPermissionDeniedHintProvider =
    Provider<ConsumeNotificationPermissionDeniedHint>((ref) {
      return () => false;
    });

final authNotifierProvider =
    StateNotifierProvider.autoDispose<AuthNotifier, AuthState>((ref) {
      return AuthNotifier(
        loginUseCase: ref.watch(loginUseCaseProvider),
        onAuthenticatedTokenSync: ref.watch(
          authOnAuthenticatedTokenSyncProvider,
        ),
        consumeNotificationPermissionDeniedHint: ref.watch(
          authConsumeNotificationPermissionDeniedHintProvider,
        ),
      );
    });

final authNotifierByDependenciesProvider = StateNotifierProvider.autoDispose
    .family<AuthNotifier, AuthState, AuthNotifierDependencies>((
      ref,
      dependencies,
    ) {
      return AuthNotifier(
        loginUseCase: dependencies.loginUseCase,
        onAuthenticatedTokenSync: dependencies.onAuthenticatedTokenSync,
        consumeNotificationPermissionDeniedHint:
            dependencies.consumeNotificationPermissionDeniedHint,
      );
    });

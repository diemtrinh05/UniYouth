import 'package:flutter_riverpod/legacy.dart';

import '../../../../../../domain/usecases/profile/get_my_profile_usecase.dart';
import 'home_dashboard_notifier.dart';
import 'home_dashboard_state.dart';

class HomeDashboardNotifierDependencies {
  const HomeDashboardNotifierDependencies({
    required this.getMyProfileUseCase,
    required this.onLogout,
  });

  final GetMyProfileUseCase getMyProfileUseCase;
  final HomeDashboardLogout onLogout;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is HomeDashboardNotifierDependencies &&
        other.getMyProfileUseCase == getMyProfileUseCase &&
        other.onLogout == onLogout;
  }

  @override
  int get hashCode => Object.hash(getMyProfileUseCase, onLogout);
}

final homeDashboardNotifierByDependenciesProvider = StateNotifierProvider
    .autoDispose
    .family<
      HomeDashboardNotifier,
      HomeDashboardState,
      HomeDashboardNotifierDependencies
    >((ref, dependencies) {
      return HomeDashboardNotifier(
        getMyProfileUseCase: dependencies.getMyProfileUseCase,
        onLogout: dependencies.onLogout,
      );
    });

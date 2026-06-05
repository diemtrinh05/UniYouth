import 'package:flutter_riverpod/legacy.dart';

import '../../../../../../core/error/app_error.dart';
import '../../../../../../domain/usecases/profile/get_my_profile_usecase.dart';
import 'home_dashboard_state.dart';

typedef HomeDashboardLogout = Future<void> Function();

class HomeDashboardNotifier extends StateNotifier<HomeDashboardState> {
  HomeDashboardNotifier({
    required GetMyProfileUseCase getMyProfileUseCase,
    required HomeDashboardLogout onLogout,
  }) : _getMyProfileUseCase = getMyProfileUseCase,
       _onLogout = onLogout,
       super(const HomeDashboardState());

  final GetMyProfileUseCase _getMyProfileUseCase;
  final HomeDashboardLogout _onLogout;
  bool _isDisposed = false;

  Future<void> syncProfile() async {
    _setState(state.copyWith(isLoadingProfile: true));
    try {
      final profile = await _getMyProfileUseCase();
      _setState(
        state.copyWith(
          fullName: profile.fullName?.trim(),
          avatarUrl: profile.avatarUrl?.trim(),
          hasActiveFaceProfile: profile.hasActiveFaceProfile,
          isLoadingProfile: false,
        ),
      );
    } on AppError catch (_) {
      _setState(state.copyWith(isLoadingProfile: false));
    } catch (_) {
      _setState(state.copyWith(isLoadingProfile: false));
    }
  }

  Future<void> logout() async {
    if (state.isLoggingOut) {
      return;
    }
    _setState(state.copyWith(isLoggingOut: true));
    await _onLogout();
  }

  void _setState(HomeDashboardState nextState) {
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

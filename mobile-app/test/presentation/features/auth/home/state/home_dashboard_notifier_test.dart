import 'package:flutter_test/flutter_test.dart';
import 'package:uniyouth_app/domain/usecases/profile/get_my_profile_usecase.dart';
import 'package:uniyouth_app/presentation/features/auth/home/state/home_dashboard_notifier.dart';

void main() {
  test('logout marks dashboard state and triggers logout callback', () async {
    var logoutCallCount = 0;
    final notifier = HomeDashboardNotifier(
      getMyProfileUseCase: GetMyProfileUseCase(
        repository: _FakeGetMyProfileRepository(),
      ),
      onLogout: () async {
        logoutCallCount += 1;
      },
    );
    addTearDown(notifier.dispose);

    await notifier.logout();

    expect(logoutCallCount, 1);
    expect(notifier.state.isLoggingOut, isTrue);
  });
}

class _FakeGetMyProfileRepository implements GetMyProfileRepository {
  @override
  Future<MyProfile> getMyProfile() async {
    return MyProfile(
      userId: 1,
      code: 'SV001',
      fullName: 'Uni Youth',
      email: 'sv001@example.com',
      phone: '0900000000',
      avatarUrl: null,
      gender: true,
      dateOfBirth: DateTime(2000, 1, 1),
      address: 'HCM',
      role: 'student',
      unitName: 'Unit',
      unitId: 1,
      positionId: 1,
      joinDate: DateTime(2024, 1, 1),
      position: 'member',
      instituteName: 'Institute',
      instituteId: 1,
      status: 1,
      lastLoginDate: DateTime(2026, 1, 1),
      createdDate: DateTime(2025, 1, 1),
    );
  }
}

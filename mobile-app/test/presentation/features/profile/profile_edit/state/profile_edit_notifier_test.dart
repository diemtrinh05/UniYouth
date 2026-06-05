import 'package:flutter_test/flutter_test.dart';
import 'package:uniyouth_app/domain/usecases/profile/get_my_profile_usecase.dart';
import 'package:uniyouth_app/domain/usecases/profile/update_my_profile_usecase.dart';
import 'package:uniyouth_app/presentation/features/profile/profile_edit/state/profile_edit_notifier.dart';

void main() {
  group('ProfileEditNotifier', () {
    test(
      'submit sends normalized payload and returns true on success',
      () async {
        final repository = _FakeUpdateMyProfileRepository();
        final notifier = ProfileEditNotifier(
          initialProfile: _profile(),
          updateMyProfileUseCase: UpdateMyProfileUseCase(
            repository: repository,
          ),
        );
        addTearDown(notifier.dispose);

        final didSucceed = await notifier.submit(
          fullNameText: '  Nguyen Van B  ',
          phoneText: '  0901234567  ',
          avatarUrlText: '  https://cdn/new.png  ',
          addressText: '  District 1  ',
          positionId: 11,
          instituteId: 22,
        );

        expect(didSucceed, isTrue);
        expect(repository.callCount, 1);
        expect(repository.lastInput?.fullName, 'Nguyen Van B');
        expect(repository.lastInput?.phone, '0901234567');
        expect(repository.lastInput?.avatarUrl, 'https://cdn/new.png');
        expect(repository.lastInput?.address, 'District 1');
        expect(repository.lastInput?.positionId, 11);
        expect(repository.lastInput?.instituteId, 22);
        expect(notifier.state.isSubmitting, isFalse);
      },
    );

    test(
      'validateDateOfBirthBeforeSubmit returns false when date is invalid',
      () {
        final notifier = ProfileEditNotifier(
          initialProfile: _profile(),
          updateMyProfileUseCase: UpdateMyProfileUseCase(
            repository: _FakeUpdateMyProfileRepository(),
          ),
        );
        addTearDown(notifier.dispose);

        notifier.setDateOfBirth(DateTime.now().add(const Duration(days: 1)));
        final isValid = notifier.validateDateOfBirthBeforeSubmit();

        expect(isValid, isFalse);
        expect(notifier.state.dateOfBirthError, isNotNull);
      },
    );
  });
}

class _FakeUpdateMyProfileRepository implements UpdateMyProfileRepository {
  int callCount = 0;
  UpdateMyProfileInput? lastInput;

  @override
  Future<MyProfile> updateMyProfile({
    required UpdateMyProfileInput input,
  }) async {
    callCount += 1;
    lastInput = input;
    return _profile(fullName: input.fullName);
  }
}

MyProfile _profile({String fullName = 'Nguyen Van A'}) {
  return MyProfile(
    userId: 1,
    code: 'SV001',
    fullName: fullName,
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

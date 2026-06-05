import 'get_my_profile_usecase.dart';

class UpdateMyProfileInput {
  const UpdateMyProfileInput({
    required this.fullName,
    required this.phone,
    required this.avatarUrl,
    required this.gender,
    required this.dateOfBirth,
    required this.address,
    required this.positionId,
    required this.instituteId,
    required this.joinDate,
  });

  final String fullName;
  final String? phone;
  final String? avatarUrl;
  final bool? gender;
  final DateTime? dateOfBirth;
  final String? address;
  final int? positionId;
  final int? instituteId;
  final DateTime? joinDate;
}

abstract class UpdateMyProfileRepository {
  Future<MyProfile> updateMyProfile({required UpdateMyProfileInput input});
}

class UpdateMyProfileUseCase {
  const UpdateMyProfileUseCase({required UpdateMyProfileRepository repository})
    : _repository = repository;

  final UpdateMyProfileRepository _repository;

  // Submit profile update payload to backend /api/Users/me.
  Future<MyProfile> call({required UpdateMyProfileInput input}) {
    return _repository.updateMyProfile(input: input);
  }
}

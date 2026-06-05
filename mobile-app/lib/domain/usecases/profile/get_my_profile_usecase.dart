class MyProfile {
  const MyProfile({
    required this.userId,
    required this.code,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.avatarUrl,
    required this.gender,
    required this.dateOfBirth,
    required this.address,
    required this.role,
    required this.unitName,
    required this.unitId,
    required this.positionId,
    required this.joinDate,
    required this.position,
    required this.instituteName,
    required this.instituteId,
    required this.status,
    required this.lastLoginDate,
    required this.createdDate,
    this.hasActiveFaceProfile = false,
    this.faceProfileImageUrl,
    this.faceProfileUpdatedDate,
    this.faceProfileQualityScore,
  });

  final int userId;
  final String? code;
  final String? fullName;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final bool? gender;
  final DateTime? dateOfBirth;
  final String? address;
  final String? role;
  final String? unitName;
  final int? unitId;
  final int? positionId;
  final DateTime? joinDate;
  final String? position;
  final String? instituteName;
  final int? instituteId;
  final int? status;
  final DateTime? lastLoginDate;
  final DateTime? createdDate;
  final bool hasActiveFaceProfile;
  final String? faceProfileImageUrl;
  final DateTime? faceProfileUpdatedDate;
  final double? faceProfileQualityScore;
}

abstract class GetMyProfileRepository {
  Future<MyProfile> getMyProfile();
}

class GetMyProfileUseCase {
  const GetMyProfileUseCase({required GetMyProfileRepository repository})
    : _repository = repository;

  final GetMyProfileRepository _repository;

  // Load current user profile from backend /api/Users/me.
  Future<MyProfile> call() {
    return _repository.getMyProfile();
  }
}

import '../../../../../../domain/usecases/profile/get_my_profile_usecase.dart';

class ProfileEditState {
  const ProfileEditState({
    required this.initialProfile,
    this.isSubmitting = false,
    this.gender,
    this.dateOfBirth,
    this.joinDate,
    this.dateOfBirthError,
    this.submitMessage,
    this.fullNameBackendError,
    this.phoneBackendError,
    this.avatarUrlBackendError,
    this.addressBackendError,
    this.instituteIdBackendError,
    this.positionIdBackendError,
    this.genderBackendError,
    this.dateOfBirthBackendError,
    this.joinDateBackendError,
  });

  final MyProfile initialProfile;
  final bool isSubmitting;
  final bool? gender;
  final DateTime? dateOfBirth;
  final DateTime? joinDate;
  final String? dateOfBirthError;
  final String? submitMessage;

  final String? fullNameBackendError;
  final String? phoneBackendError;
  final String? avatarUrlBackendError;
  final String? addressBackendError;
  final String? instituteIdBackendError;
  final String? positionIdBackendError;
  final String? genderBackendError;
  final String? dateOfBirthBackendError;
  final String? joinDateBackendError;

  ProfileEditState copyWith({
    bool? isSubmitting,
    bool? gender,
    bool clearGender = false,
    DateTime? dateOfBirth,
    bool clearDateOfBirth = false,
    DateTime? joinDate,
    bool clearJoinDate = false,
    String? dateOfBirthError,
    bool clearDateOfBirthError = false,
    String? submitMessage,
    bool clearSubmitMessage = false,
    String? fullNameBackendError,
    bool clearFullNameBackendError = false,
    String? phoneBackendError,
    bool clearPhoneBackendError = false,
    String? avatarUrlBackendError,
    bool clearAvatarUrlBackendError = false,
    String? addressBackendError,
    bool clearAddressBackendError = false,
    String? instituteIdBackendError,
    bool clearInstituteIdBackendError = false,
    String? positionIdBackendError,
    bool clearPositionIdBackendError = false,
    String? genderBackendError,
    bool clearGenderBackendError = false,
    String? dateOfBirthBackendError,
    bool clearDateOfBirthBackendError = false,
    String? joinDateBackendError,
    bool clearJoinDateBackendError = false,
  }) {
    return ProfileEditState(
      initialProfile: initialProfile,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      gender: clearGender ? null : (gender ?? this.gender),
      dateOfBirth: clearDateOfBirth ? null : (dateOfBirth ?? this.dateOfBirth),
      joinDate: clearJoinDate ? null : (joinDate ?? this.joinDate),
      dateOfBirthError: clearDateOfBirthError
          ? null
          : (dateOfBirthError ?? this.dateOfBirthError),
      submitMessage: clearSubmitMessage
          ? null
          : (submitMessage ?? this.submitMessage),
      fullNameBackendError: clearFullNameBackendError
          ? null
          : (fullNameBackendError ?? this.fullNameBackendError),
      phoneBackendError: clearPhoneBackendError
          ? null
          : (phoneBackendError ?? this.phoneBackendError),
      avatarUrlBackendError: clearAvatarUrlBackendError
          ? null
          : (avatarUrlBackendError ?? this.avatarUrlBackendError),
      addressBackendError: clearAddressBackendError
          ? null
          : (addressBackendError ?? this.addressBackendError),
      instituteIdBackendError: clearInstituteIdBackendError
          ? null
          : (instituteIdBackendError ?? this.instituteIdBackendError),
      positionIdBackendError: clearPositionIdBackendError
          ? null
          : (positionIdBackendError ?? this.positionIdBackendError),
      genderBackendError: clearGenderBackendError
          ? null
          : (genderBackendError ?? this.genderBackendError),
      dateOfBirthBackendError: clearDateOfBirthBackendError
          ? null
          : (dateOfBirthBackendError ?? this.dateOfBirthBackendError),
      joinDateBackendError: clearJoinDateBackendError
          ? null
          : (joinDateBackendError ?? this.joinDateBackendError),
    );
  }
}

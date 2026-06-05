import 'package:flutter_riverpod/legacy.dart';

import '../../../../../../core/error/app_error.dart';
import '../../../../../../core/error/error_presenter.dart';
import '../../../../../../core/utils/validators/profile_validators.dart';
import '../../../../../../domain/usecases/profile/get_my_profile_usecase.dart';
import '../../../../../../domain/usecases/profile/update_my_profile_usecase.dart';
import '../../../../shared/forms/backend_field_error_picker.dart';
import 'profile_edit_state.dart';

enum ProfileEditBackendField {
  fullName,
  phone,
  avatarUrl,
  address,
  instituteId,
  positionId,
  gender,
  dateOfBirth,
  joinDate,
}

class ProfileEditNotifier extends StateNotifier<ProfileEditState> {
  ProfileEditNotifier({
    required MyProfile initialProfile,
    required UpdateMyProfileUseCase updateMyProfileUseCase,
  }) : _updateMyProfileUseCase = updateMyProfileUseCase,
       super(
         ProfileEditState(
           initialProfile: initialProfile,
           gender: initialProfile.gender,
           dateOfBirth: initialProfile.dateOfBirth,
           joinDate: initialProfile.joinDate,
         ),
       );

  final UpdateMyProfileUseCase _updateMyProfileUseCase;
  bool _isDisposed = false;

  bool validateDateOfBirthBeforeSubmit() {
    final error = ProfileValidators.validateDateOfBirth(state.dateOfBirth);
    _setState(state.copyWith(dateOfBirthError: error));
    return error == null;
  }

  void setGender(bool? value) {
    _setState(state.copyWith(gender: value, clearGenderBackendError: true));
  }

  void setDateOfBirth(DateTime value) {
    final normalized = DateTime(value.year, value.month, value.day);
    _setState(
      state.copyWith(
        dateOfBirth: normalized,
        dateOfBirthError: ProfileValidators.validateDateOfBirth(normalized),
        clearDateOfBirthBackendError: true,
      ),
    );
  }

  void setJoinDate(DateTime value) {
    final normalized = DateTime(value.year, value.month, value.day);
    _setState(
      state.copyWith(joinDate: normalized, clearJoinDateBackendError: true),
    );
  }

  void clearBackendError(ProfileEditBackendField field) {
    switch (field) {
      case ProfileEditBackendField.fullName:
        _setState(state.copyWith(clearFullNameBackendError: true));
        break;
      case ProfileEditBackendField.phone:
        _setState(state.copyWith(clearPhoneBackendError: true));
        break;
      case ProfileEditBackendField.avatarUrl:
        _setState(state.copyWith(clearAvatarUrlBackendError: true));
        break;
      case ProfileEditBackendField.address:
        _setState(state.copyWith(clearAddressBackendError: true));
        break;
      case ProfileEditBackendField.instituteId:
        _setState(state.copyWith(clearInstituteIdBackendError: true));
        break;
      case ProfileEditBackendField.positionId:
        _setState(state.copyWith(clearPositionIdBackendError: true));
        break;
      case ProfileEditBackendField.gender:
        _setState(state.copyWith(clearGenderBackendError: true));
        break;
      case ProfileEditBackendField.dateOfBirth:
        _setState(state.copyWith(clearDateOfBirthBackendError: true));
        break;
      case ProfileEditBackendField.joinDate:
        _setState(state.copyWith(clearJoinDateBackendError: true));
        break;
    }
  }

  Future<bool> submit({
    required String fullNameText,
    required String phoneText,
    required String avatarUrlText,
    required String addressText,
    required int? positionId,
    required int? instituteId,
  }) async {
    if (state.isSubmitting) {
      return false;
    }

    if (!validateDateOfBirthBeforeSubmit()) {
      return false;
    }

    _setState(
      state.copyWith(
        isSubmitting: true,
        clearSubmitMessage: true,
        clearFullNameBackendError: true,
        clearPhoneBackendError: true,
        clearAvatarUrlBackendError: true,
        clearAddressBackendError: true,
        clearInstituteIdBackendError: true,
        clearPositionIdBackendError: true,
        clearGenderBackendError: true,
        clearDateOfBirthBackendError: true,
        clearJoinDateBackendError: true,
      ),
    );

    var isSuccess = false;
    try {
      await _updateMyProfileUseCase(
        input: UpdateMyProfileInput(
          fullName: fullNameText.trim(),
          phone: _normalizeOptionalText(phoneText),
          avatarUrl: _normalizeOptionalText(avatarUrlText),
          gender: state.gender,
          dateOfBirth: state.dateOfBirth,
          address: _normalizeOptionalText(addressText),
          positionId: positionId,
          instituteId: instituteId,
          joinDate: state.joinDate,
        ),
      );
      isSuccess = true;
    } on AppError catch (error) {
      final fullNameError = BackendFieldErrorPicker.first(error, const <String>[
        'fullName',
        'FullName',
      ]);
      final phoneError = BackendFieldErrorPicker.first(error, const <String>[
        'phone',
        'Phone',
      ]);
      final avatarUrlError = BackendFieldErrorPicker.first(
        error,
        const <String>['avatarUrl', 'AvatarUrl'],
      );
      final addressError = BackendFieldErrorPicker.first(error, const <String>[
        'address',
        'Address',
      ]);
      final instituteIdError = BackendFieldErrorPicker.first(
        error,
        const <String>['instituteId', 'InstituteId'],
      );
      final joinDateError = BackendFieldErrorPicker.first(error, const <String>[
        'joinDate',
        'JoinDate',
      ]);
      final positionIdError = BackendFieldErrorPicker.first(
        error,
        const <String>['positionId', 'PositionId', 'position', 'Position'],
      );
      final genderError = BackendFieldErrorPicker.first(error, const <String>[
        'gender',
        'Gender',
      ]);
      final dateOfBirthError = BackendFieldErrorPicker.first(
        error,
        const <String>['dateOfBirth', 'DateOfBirth'],
      );

      final hasAnyFieldError =
          fullNameError != null ||
          phoneError != null ||
          avatarUrlError != null ||
          addressError != null ||
          instituteIdError != null ||
          joinDateError != null ||
          positionIdError != null ||
          genderError != null ||
          dateOfBirthError != null;

      _setState(
        state.copyWith(
          fullNameBackendError: fullNameError,
          phoneBackendError: phoneError,
          avatarUrlBackendError: avatarUrlError,
          addressBackendError: addressError,
          instituteIdBackendError: instituteIdError,
          joinDateBackendError: joinDateError,
          positionIdBackendError: positionIdError,
          genderBackendError: genderError,
          dateOfBirthBackendError: dateOfBirthError,
          submitMessage: hasAnyFieldError
              ? null
              : ErrorPresenter.presentAppError(
                  error,
                  operation: 'cập nhật hồ sơ',
                ).message,
        ),
      );
    } on FormatException catch (_) {
      _setState(
        state.copyWith(
          submitMessage: ErrorPresenter.presentException(
            operation: 'cập nhật hồ sơ',
          ).message,
        ),
      );
    } finally {
      _setState(state.copyWith(isSubmitting: false));
    }
    return isSuccess;
  }

  String? _normalizeOptionalText(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  void _setState(ProfileEditState nextState) {
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

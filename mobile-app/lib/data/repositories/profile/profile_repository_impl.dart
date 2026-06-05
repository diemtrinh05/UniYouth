import 'dart:convert';

import '../../../domain/usecases/profile/get_my_profile_usecase.dart';
import '../../../domain/usecases/profile/get_position_options_usecase.dart';
import '../../../domain/usecases/profile/change_password_usecase.dart';
import '../../../domain/usecases/profile/request_face_profile_reauth_otp_usecase.dart';
import '../../../domain/usecases/profile/update_my_profile_usecase.dart';
import '../../../domain/usecases/profile/upload_avatar_usecase.dart';
import '../../../domain/usecases/profile/delete_avatar_usecase.dart';
import '../../../domain/usecases/profile/enroll_face_profile_usecase.dart';
import '../../datasources/remote/users_remote_datasource.dart';
import '../../models/profile/change_password_request_model.dart';
import '../../models/profile/update_my_profile_request_model.dart';

class ProfileRepositoryImpl
    implements
        GetMyProfileRepository,
        GetPositionOptionsRepository,
        ChangePasswordRepository,
        UpdateMyProfileRepository,
        UploadAvatarRepository,
        DeleteAvatarRepository,
        EnrollFaceProfileRepository,
        RequestFaceProfileReauthOtpRepository {
  ProfileRepositoryImpl({required UsersRemoteDataSource usersRemoteDataSource})
    : _usersRemoteDataSource = usersRemoteDataSource;

  final UsersRemoteDataSource _usersRemoteDataSource;

  @override
  Future<MyProfile> getMyProfile() async {
    final response = await _usersRemoteDataSource.getMyProfile();

    // Map data model to domain model before passing to presentation layer.
    return MyProfile(
      userId: response.userId,
      code: response.code,
      fullName: response.fullName,
      email: response.email,
      phone: response.phone,
      avatarUrl: response.avatarUrl,
      gender: response.gender,
      dateOfBirth: response.dateOfBirth,
      address: response.address,
      role: response.role,
      unitName: response.unitName,
      unitId: response.unitId,
      positionId: response.positionId,
      joinDate: response.joinDate,
      position: response.position,
      instituteName: response.instituteName,
      instituteId: response.instituteId,
      status: response.status,
      lastLoginDate: response.lastLoginDate,
      createdDate: response.createdDate,
      hasActiveFaceProfile: response.hasActiveFaceProfile,
      faceProfileImageUrl: response.faceProfileImageUrl,
      faceProfileUpdatedDate: response.faceProfileUpdatedDate,
      faceProfileQualityScore: response.faceProfileQualityScore,
    );
  }

  @override
  Future<MyProfile> updateMyProfile({
    required UpdateMyProfileInput input,
  }) async {
    final response = await _usersRemoteDataSource.updateMyProfile(
      request: UpdateMyProfileRequestModel(
        fullName: input.fullName,
        phone: input.phone,
        avatarUrl: input.avatarUrl,
        gender: input.gender,
        dateOfBirth: input.dateOfBirth,
        address: input.address,
        positionId: input.positionId,
        instituteId: input.instituteId,
        joinDate: input.joinDate,
      ),
    );

    // Keep update response mapping consistent with getMyProfile.
    return MyProfile(
      userId: response.userId,
      code: response.code,
      fullName: response.fullName,
      email: response.email,
      phone: response.phone,
      avatarUrl: response.avatarUrl,
      gender: response.gender,
      dateOfBirth: response.dateOfBirth,
      address: response.address,
      role: response.role,
      unitName: response.unitName,
      unitId: response.unitId,
      positionId: response.positionId,
      joinDate: response.joinDate,
      position: response.position,
      instituteName: response.instituteName,
      instituteId: response.instituteId,
      status: response.status,
      lastLoginDate: response.lastLoginDate,
      createdDate: response.createdDate,
      hasActiveFaceProfile: response.hasActiveFaceProfile,
      faceProfileImageUrl: response.faceProfileImageUrl,
      faceProfileUpdatedDate: response.faceProfileUpdatedDate,
      faceProfileQualityScore: response.faceProfileQualityScore,
    );
  }

  @override
  Future<UploadAvatarResult> uploadAvatar({
    required UploadAvatarFile file,
  }) async {
    final response = await _usersRemoteDataSource.uploadAvatar(
      bytes: file.bytes,
      fileName: file.fileName,
    );

    return UploadAvatarResult(
      avatarUrl: response.avatarUrl,
      message: response.message,
    );
  }

  @override
  Future<void> deleteAvatar() {
    return _usersRemoteDataSource.deleteAvatar();
  }

  @override
  Future<EnrollFaceProfileResult> enrollFaceProfile({
    required EnrollFaceProfileInput input,
  }) async {
    final response = await _usersRemoteDataSource.enrollFaceProfile(
      faceImageBase64: base64Encode(input.imageBytes),
      faceImageMimeType: input.imageMimeType,
      reauthOtpCode: input.reauthOtpCode,
    );

    return EnrollFaceProfileResult(
      imageUrl: response.imageUrl,
      message: response.message,
      qualityScore: response.qualityScore,
    );
  }

  @override
  Future<RequestFaceProfileReauthOtpResult>
  requestFaceProfileReauthOtp() async {
    final response = await _usersRemoteDataSource.requestFaceProfileReauthOtp();
    return RequestFaceProfileReauthOtpResult(message: response.message);
  }

  @override
  Future<ChangePasswordResult> changePassword({
    required ChangePasswordInput input,
  }) async {
    final response = await _usersRemoteDataSource.changePassword(
      request: ChangePasswordRequestModel(
        currentPassword: input.currentPassword,
        newPassword: input.newPassword,
        confirmNewPassword: input.confirmNewPassword,
      ),
    );

    return ChangePasswordResult(
      success: response.success,
      message: response.message,
      additionalInfo: response.additionalInfo,
    );
  }

  @override
  Future<List<PositionOption>> getPositionOptions() async {
    final response = await _usersRemoteDataSource.getPositions();
    return response
        .map(
          (item) => PositionOption(
            positionId: item.positionId,
            positionCode: item.positionCode,
            positionName: item.positionName,
            unitId: item.unitId,
            unitName: item.unitName,
            instituteId: item.instituteId,
            instituteName: item.instituteName,
          ),
        )
        .toList(growable: false);
  }
}

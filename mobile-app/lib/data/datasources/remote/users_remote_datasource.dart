import 'dart:convert';

import 'package:dio/dio.dart';

import '../../models/profile/avatar_upload_result_model.dart';
import '../../models/profile/face_profile_enrollment_result_model.dart';
import '../../models/profile/face_profile_reauth_otp_result_model.dart';
import '../../models/profile/change_password_request_model.dart';
import '../../models/profile/change_password_result_model.dart';
import '../../models/profile/my_profile_model.dart';
import '../../models/profile/position_option_model.dart';
import '../../models/profile/update_my_profile_request_model.dart';
import 'base_remote_datasource.dart';

class UsersRemoteDataSource extends BaseRemoteDataSource {
  UsersRemoteDataSource({required Dio dio}) : super(dio);

  Future<MyProfileModel> getMyProfile() async {
    final response = await runRequest(() => dio.get<dynamic>('/api/Users/me'));

    final typedBody = _asStringDynamicMap(
      response.data,
      fallbackMessage: 'Invalid profile response body.',
    );
    return MyProfileModel.fromApiResponse(typedBody);
  }

  Future<MyProfileModel> updateMyProfile({
    required UpdateMyProfileRequestModel request,
  }) async {
    final response = await runRequest(
      () => dio.put<dynamic>('/api/Users/me', data: request.toJson()),
    );

    final typedBody = _asStringDynamicMap(
      response.data,
      fallbackMessage: 'Invalid update profile response body.',
    );
    return MyProfileModel.fromApiResponse(typedBody);
  }

  Future<List<PositionOptionModel>> getPositions() async {
    final response = await runRequest(() => dio.get<dynamic>('/api/positions'));

    final typedBody = _asStringDynamicMap(
      response.data,
      fallbackMessage: 'Invalid positions response body.',
    );
    final data = typedBody['data'];
    if (data is! List) {
      throw const FormatException('Invalid positions payload.');
    }

    return data
        .whereType<Map>()
        .map(
          (item) => PositionOptionModel.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList(growable: false);
  }

  Future<AvatarUploadResultModel> uploadAvatar({
    required List<int> bytes,
    required String fileName,
  }) async {
    final formData = FormData.fromMap(<String, dynamic>{
      // Swagger contract: multipart field name must be `File`.
      'File': MultipartFile.fromBytes(bytes, filename: fileName),
    });

    final response = await runRequest(
      () => dio.post<dynamic>('/api/Users/me/avatar', data: formData),
    );

    final typedBody = _asStringDynamicMap(
      response.data,
      fallbackMessage: 'Invalid avatar upload response body.',
    );
    return AvatarUploadResultModel.fromApiResponse(typedBody);
  }

  Future<void> deleteAvatar() async {
    await runRequest(() => dio.delete<dynamic>('/api/Users/me/avatar'));
  }

  Future<FaceProfileEnrollmentResultModel> enrollFaceProfile({
    required String faceImageBase64,
    required String faceImageMimeType,
    String? reauthOtpCode,
  }) async {
    final response = await runRequest(
      () => dio.post<dynamic>(
        '/api/Users/me/face-profile',
        data: <String, dynamic>{
          'faceImageBase64': faceImageBase64,
          'faceImageMimeType': faceImageMimeType,
          if ((reauthOtpCode ?? '').trim().isNotEmpty)
            'reauthOtpCode': reauthOtpCode,
        },
      ),
    );

    final typedBody = _asStringDynamicMap(
      response.data,
      fallbackMessage: 'Invalid face profile enrollment response body.',
    );
    return FaceProfileEnrollmentResultModel.fromApiResponse(typedBody);
  }

  Future<FaceProfileReauthOtpResultModel> requestFaceProfileReauthOtp() async {
    final response = await runRequest(
      () => dio.post<dynamic>('/api/Users/me/face-profile/re-auth-otp'),
    );

    final typedBody = _asStringDynamicMap(
      response.data,
      fallbackMessage: 'Invalid face profile reauth otp response body.',
    );
    return FaceProfileReauthOtpResultModel.fromApiResponse(typedBody);
  }

  Future<ChangePasswordResultModel> changePassword({
    required ChangePasswordRequestModel request,
  }) async {
    final response = await runRequest(
      () => dio.post<dynamic>(
        '/api/Users/change-password',
        data: request.toJson(),
      ),
    );

    final typedBody = _asStringDynamicMap(
      response.data,
      fallbackMessage: 'Invalid change password response body.',
    );
    return ChangePasswordResultModel.fromApiResponse(typedBody);
  }

  Map<String, dynamic> _asStringDynamicMap(
    Object? data, {
    required String fallbackMessage,
  }) {
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }

    if (data is String) {
      final trimmed = data.trim();
      if (trimmed.isNotEmpty) {
        try {
          final decoded = jsonDecode(trimmed);
          if (decoded is Map) {
            return decoded.map((key, value) => MapEntry(key.toString(), value));
          }
        } on FormatException {
          // Fall through and throw below.
        }
      }
    }

    throw FormatException(fallbackMessage);
  }
}

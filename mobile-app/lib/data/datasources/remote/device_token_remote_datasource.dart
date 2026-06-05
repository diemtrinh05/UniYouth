import 'package:dio/dio.dart';

import '../../../core/notifications/device_push_platform.dart';
import 'base_remote_datasource.dart';

class DeviceTokenRemoteDataSource extends BaseRemoteDataSource {
  DeviceTokenRemoteDataSource({
    required Dio dio,
  }) : super(dio);

  Future<void> registerDeviceToken({
    required DevicePushPlatform platform,
    required String token,
    String? deviceId,
  }) {
    return runRequest(() async {
      await dio.post<dynamic>(
        '/api/device-tokens',
        data: <String, dynamic>{
          'platform': platform.apiValue,
          'token': token,
          if (deviceId != null && deviceId.trim().isNotEmpty) 'deviceId': deviceId,
        },
      );
    });
  }

  Future<void> unregisterDeviceToken({
    required DevicePushPlatform platform,
    required String token,
  }) {
    return runRequest(() async {
      await dio.delete<dynamic>(
        '/api/device-tokens',
        data: <String, dynamic>{
          'platform': platform.apiValue,
          'token': token,
        },
      );
    });
  }
}

import '../../../core/notifications/device_push_platform_resolver.dart';
import '../../../core/notifications/device_push_token_provider.dart';
import '../../../domain/usecases/device_token/register_device_token_usecase.dart';
import '../../../domain/usecases/device_token/unregister_device_token_usecase.dart';
import '../../datasources/remote/device_token_remote_datasource.dart';

class DeviceTokenRepositoryImpl
    implements RegisterDeviceTokenRepository, UnregisterDeviceTokenRepository {
  DeviceTokenRepositoryImpl({
    required DeviceTokenRemoteDataSource remoteDataSource,
    required DevicePushPlatformResolver platformResolver,
    required DevicePushTokenProvider tokenProvider,
  })  : _remoteDataSource = remoteDataSource,
        _platformResolver = platformResolver,
        _tokenProvider = tokenProvider;

  final DeviceTokenRemoteDataSource _remoteDataSource;
  final DevicePushPlatformResolver _platformResolver;
  final DevicePushTokenProvider _tokenProvider;

  @override
  Future<void> registerDeviceToken() async {
    final token = await _tokenProvider.getToken();
    if (token == null || token.trim().isEmpty) {
      return;
    }

    await _remoteDataSource.registerDeviceToken(
      platform: _platformResolver.resolve(),
      token: token.trim(),
    );
  }

  @override
  Future<void> unregisterDeviceToken() async {
    final token = await _tokenProvider.getToken();
    if (token == null || token.trim().isEmpty) {
      return;
    }

    await _remoteDataSource.unregisterDeviceToken(
      platform: _platformResolver.resolve(),
      token: token.trim(),
    );
  }
}

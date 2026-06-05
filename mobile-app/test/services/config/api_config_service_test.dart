import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uniyouth_app/services/config/api_config_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ApiConfigService', () {
    test('uses public API base URL when no server IP is stored', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final preferences = await SharedPreferences.getInstance();
      final service = ApiConfigService(
        preferences: preferences,
        appEnv: 'dev',
        configuredBaseUrl: ApiConfigService.publicApiBaseUrl,
        isProduct: false,
      );

      expect(service.savedServerIp, isEmpty);
      expect(service.effectiveBaseUrl, 'http://localhost:5160');
    });

    test('saves server IP and builds dev base URL from preferences', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final preferences = await SharedPreferences.getInstance();
      final service = ApiConfigService(
        preferences: preferences,
        appEnv: 'dev',
        configuredBaseUrl: ApiConfigService.publicApiBaseUrl,
        isProduct: false,
      );

      final baseUrl = await service.saveServerIp('192.168.1.12');

      expect(
        preferences.getString(ApiConfigService.apiServerIpPreferenceKey),
        '192.168.1.12',
      );
      expect(baseUrl, 'http://192.168.1.12:5160');
      expect(service.effectiveBaseUrl, 'http://192.168.1.12:5160');
    });

    test('clears stored server IP when saved value is empty', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        ApiConfigService.apiServerIpPreferenceKey: '192.168.1.12',
      });
      final preferences = await SharedPreferences.getInstance();
      final service = ApiConfigService(
        preferences: preferences,
        appEnv: 'dev',
        configuredBaseUrl: ApiConfigService.publicApiBaseUrl,
        isProduct: false,
      );

      final baseUrl = await service.saveServerIp('  ');

      expect(
        preferences.getString(ApiConfigService.apiServerIpPreferenceKey),
        isNull,
      );
      expect(baseUrl, 'http://localhost:5160');
      expect(service.effectiveBaseUrl, 'http://localhost:5160');
    });
  });
}

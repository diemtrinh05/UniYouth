import 'package:shared_preferences/shared_preferences.dart';
import 'package:uniyouth_app/services/config/api_config_service.dart';

Future<ApiConfigService> createTestApiConfigService() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final preferences = await SharedPreferences.getInstance();
  return ApiConfigService(
    preferences: preferences,
    appEnv: 'prod',
    configuredBaseUrl: 'https://api.test.local',
    isProduct: false,
  );
}

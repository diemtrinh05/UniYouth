import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfigService extends ChangeNotifier {
  static const String publicApiBaseUrl = '';

  factory ApiConfigService.fromEnvironment({
    required SharedPreferences preferences,
  }) {
    return ApiConfigService(
      preferences: preferences,
      appEnv: const String.fromEnvironment('APP_ENV', defaultValue: 'dev'),
      configuredBaseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: publicApiBaseUrl,
      ),
      isProduct: const bool.fromEnvironment('dart.vm.product'),
    );
  }

  ApiConfigService({
    required SharedPreferences preferences,
    required String appEnv,
    required String configuredBaseUrl,
    required bool isProduct,
  }) : _preferences = preferences,
       _configuredBaseUrl = configuredBaseUrl.trim(),
       _isProduct = isProduct,
       _normalizedAppEnv = appEnv.trim().toLowerCase();

  static const String apiServerIpPreferenceKey = 'api_server_ip';
  static const int devServerPort = 5160;
  static const String defaultDevHost = 'localhost';
  static const Set<String> _allowedEnvs = <String>{'dev', 'staging', 'prod'};

  final SharedPreferences _preferences;
  final String _configuredBaseUrl;
  final bool _isProduct;
  final String _normalizedAppEnv;

  String get normalizedAppEnv => _normalizedAppEnv;
  bool get isDevEnvironment => _normalizedAppEnv == 'dev';

  String get savedServerIp =>
      _preferences.getString(apiServerIpPreferenceKey)?.trim() ?? '';

  String get effectiveBaseUrl => resolveBaseUrl();

  String previewBaseUrl(String serverIp) {
    return _buildDevBaseUrl(serverIp.trim());
  }

  String resolveBaseUrl() {
    _validateEnvironment();
    if (isDevEnvironment) {
      if (savedServerIp.isNotEmpty) {
        return _buildDevBaseUrl(savedServerIp);
      }
      if (_configuredBaseUrl.isNotEmpty) {
        return _requireConfiguredBaseUrl();
      }
      return _buildDevBaseUrl(savedServerIp);
    }
    return _requireConfiguredBaseUrl();
  }

  Future<String> saveServerIp(String serverIp) async {
    final normalizedIp = serverIp.trim();
    if (normalizedIp.isEmpty) {
      await _preferences.remove(apiServerIpPreferenceKey);
    } else {
      await _preferences.setString(apiServerIpPreferenceKey, normalizedIp);
    }
    notifyListeners();
    return resolveBaseUrl();
  }

  Future<ApiConnectionTestResult> testConnection({String? serverIp}) async {
    final baseUrl = isDevEnvironment
        ? _buildDevBaseUrl(serverIp?.trim() ?? savedServerIp)
        : resolveBaseUrl();

    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
        sendTimeout: const Duration(seconds: 5),
        responseType: ResponseType.json,
      ),
    );

    try {
      final response = await dio.get<dynamic>('/api/Auth/health');
      final statusCode = response.statusCode ?? 0;
      if (statusCode >= 200 && statusCode < 300) {
        return ApiConnectionTestResult(
          isSuccess: true,
          baseUrl: baseUrl,
          message: 'Connection success',
        );
      }
      return ApiConnectionTestResult(
        isSuccess: false,
        baseUrl: baseUrl,
        message: 'Connection failed',
      );
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      final suffix = statusCode == null
          ? error.message ?? 'Unknown error'
          : 'HTTP $statusCode';
      return ApiConnectionTestResult(
        isSuccess: false,
        baseUrl: baseUrl,
        message: 'Connection failed ($suffix)',
      );
    } catch (error) {
      return ApiConnectionTestResult(
        isSuccess: false,
        baseUrl: baseUrl,
        message: 'Connection failed ($error)',
      );
    } finally {
      dio.close(force: true);
    }
  }

  String _buildDevBaseUrl(String serverIp) {
    final host = serverIp.isEmpty ? defaultDevHost : serverIp;
    return 'http://$host:$devServerPort';
  }

  void _validateEnvironment() {
    if (_allowedEnvs.contains(_normalizedAppEnv)) {
      return;
    }
    throw StateError(
      'Invalid APP_ENV "$_normalizedAppEnv". Allowed values: dev, staging, prod.',
    );
  }

  String _requireConfiguredBaseUrl() {
    if (_configuredBaseUrl.isEmpty) {
      throw StateError(
        'Missing API_BASE_URL for APP_ENV=$_normalizedAppEnv. '
        'Set --dart-define=API_BASE_URL=...',
      );
    }

    final uri = Uri.tryParse(_configuredBaseUrl);
    final hasValidScheme =
        uri != null &&
        uri.hasAuthority &&
        (uri.scheme == 'http' || uri.scheme == 'https');
    if (!hasValidScheme) {
      throw StateError(
        'Invalid API_BASE_URL "$_configuredBaseUrl". Expected absolute http/https URL.',
      );
    }

    final host = uri.host.toLowerCase();
    final isLoopbackHost =
        host == 'localhost' ||
        host == '127.0.0.1' ||
        host == '::1' ||
        host == '10.0.2.2';
    if (_isProduct && isLoopbackHost) {
      throw StateError(
        'Invalid API_BASE_URL for production: "$_configuredBaseUrl". '
        'Loopback/localhost is not allowed in production.',
      );
    }

    return _configuredBaseUrl;
  }
}

class ApiConnectionTestResult {
  const ApiConnectionTestResult({
    required this.isSuccess,
    required this.baseUrl,
    required this.message,
  });

  final bool isSuccess;
  final String baseUrl;
  final String message;
}

import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

abstract class CheckInDeviceInfoService {
  Future<String?> buildDeviceInfo();
}

class DeviceInfoPlusCheckInDeviceInfoService
    implements CheckInDeviceInfoService {
  DeviceInfoPlusCheckInDeviceInfoService({
    DeviceInfoPlugin? deviceInfoPlugin,
    Future<PackageInfo> Function()? packageInfoLoader,
  }) : _deviceInfoPlugin = deviceInfoPlugin ?? DeviceInfoPlugin(),
       _packageInfoLoader = packageInfoLoader ?? PackageInfo.fromPlatform;

  static const int _maxLength = 255;

  final DeviceInfoPlugin _deviceInfoPlugin;
  final Future<PackageInfo> Function() _packageInfoLoader;

  @override
  Future<String?> buildDeviceInfo() async {
    try {
      final appVersion = await _resolveAppVersion();
      final platformSegment = await _resolvePlatformSegment();
      final deviceSegment = await _resolveDeviceSegment();
      final segments = <String>[
        if (platformSegment.isNotEmpty) platformSegment,
        if (deviceSegment.isNotEmpty) deviceSegment,
        if (appVersion.isNotEmpty) 'UniYouth $appVersion',
      ];
      if (segments.isEmpty) {
        return null;
      }
      final deviceInfo = segments.join(' | ').trim();
      if (deviceInfo.isEmpty) {
        return null;
      }
      return deviceInfo.length > _maxLength
          ? deviceInfo.substring(0, _maxLength)
          : deviceInfo;
    } catch (_) {
      return null;
    }
  }

  Future<String> _resolveAppVersion() async {
    try {
      final packageInfo = await _packageInfoLoader();
      return packageInfo.version.trim();
    } catch (_) {
      return '';
    }
  }

  Future<String> _resolvePlatformSegment() async {
    if (kIsWeb) {
      return 'Web';
    }

    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfoPlugin.androidInfo;
        final release = info.version.release.trim();
        return release.isEmpty ? 'Android' : 'Android $release';
      }
      if (Platform.isIOS) {
        final info = await _deviceInfoPlugin.iosInfo;
        final version = info.systemVersion.trim();
        return version.isEmpty ? 'iOS' : 'iOS $version';
      }
    } catch (_) {
      return defaultTargetPlatform.name;
    }

    return defaultTargetPlatform.name;
  }

  Future<String> _resolveDeviceSegment() async {
    if (kIsWeb) {
      return 'Browser';
    }

    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfoPlugin.androidInfo;
        final brand = info.brand.trim();
        final model = info.model.trim();
        return _combineSegments(brand, model);
      }
      if (Platform.isIOS) {
        final info = await _deviceInfoPlugin.iosInfo;
        final name = info.name.trim();
        final model = info.model.trim();
        final machine = info.utsname.machine.trim();
        return _combineSegments(name, model, machine);
      }
    } catch (_) {
      return '';
    }

    return '';
  }

  String _combineSegments(String first, String second, [String third = '']) {
    final parts = <String>{};
    for (final value in <String>[first, second, third]) {
      final normalized = value.trim();
      if (normalized.isNotEmpty) {
        parts.add(normalized);
      }
    }
    return parts.join(' ');
  }
}

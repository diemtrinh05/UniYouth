import 'package:permission_handler/permission_handler.dart';

enum CameraPermissionState {
  granted,
  denied,
  permanentlyDenied,
  restricted,
}

abstract class CameraPermissionService {
  Future<CameraPermissionState> checkPermission();

  Future<CameraPermissionState> requestPermission();

  Future<bool> openSettings();
}

class PermissionHandlerCameraPermissionService
    implements CameraPermissionService {
  const PermissionHandlerCameraPermissionService();

  @override
  Future<CameraPermissionState> checkPermission() async {
    try {
      final status = await Permission.camera.status;
      return _mapPermissionStatus(status);
    } catch (_) {
      return CameraPermissionState.denied;
    }
  }

  @override
  Future<CameraPermissionState> requestPermission() async {
    try {
      final status = await Permission.camera.request();
      return _mapPermissionStatus(status);
    } catch (_) {
      return CameraPermissionState.denied;
    }
  }

  @override
  Future<bool> openSettings() {
    return openAppSettings();
  }

  CameraPermissionState _mapPermissionStatus(PermissionStatus status) {
    if (status.isGranted) {
      return CameraPermissionState.granted;
    }
    if (status.isPermanentlyDenied) {
      return CameraPermissionState.permanentlyDenied;
    }
    if (status.isRestricted) {
      return CameraPermissionState.restricted;
    }
    return CameraPermissionState.denied;
  }
}

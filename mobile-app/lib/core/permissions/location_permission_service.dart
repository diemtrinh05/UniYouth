import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:permission_handler/permission_handler.dart';

enum LocationPermissionState { granted, denied, permanentlyDenied, restricted }

abstract class LocationPermissionService {
  Future<LocationPermissionState> checkPermission();

  Future<LocationPermissionState> requestPermission();

  Future<bool> openSettings();
}

class PermissionHandlerLocationPermissionService
    implements LocationPermissionService {
  const PermissionHandlerLocationPermissionService();

  @override
  Future<LocationPermissionState> checkPermission() async {
    if (kIsWeb) {
      final status = await geo.Geolocator.checkPermission();
      return _mapGeolocatorPermission(status);
    }

    final status = await Permission.locationWhenInUse.status;
    return _mapPermissionStatus(status);
  }

  @override
  Future<LocationPermissionState> requestPermission() async {
    if (kIsWeb) {
      final status = await geo.Geolocator.requestPermission();
      return _mapGeolocatorPermission(status);
    }

    final status = await Permission.locationWhenInUse.request();
    return _mapPermissionStatus(status);
  }

  @override
  Future<bool> openSettings() {
    if (kIsWeb) {
      // Browser permission settings cannot be opened programmatically.
      return Future<bool>.value(false);
    }
    return openAppSettings();
  }

  LocationPermissionState _mapPermissionStatus(PermissionStatus status) {
    if (status.isGranted) {
      return LocationPermissionState.granted;
    }
    if (status.isPermanentlyDenied) {
      return LocationPermissionState.permanentlyDenied;
    }
    if (status.isRestricted) {
      return LocationPermissionState.restricted;
    }
    return LocationPermissionState.denied;
  }

  LocationPermissionState _mapGeolocatorPermission(
    geo.LocationPermission status,
  ) {
    if (status == geo.LocationPermission.always ||
        status == geo.LocationPermission.whileInUse) {
      return LocationPermissionState.granted;
    }
    if (status == geo.LocationPermission.deniedForever) {
      return LocationPermissionState.permanentlyDenied;
    }
    return LocationPermissionState.denied;
  }
}

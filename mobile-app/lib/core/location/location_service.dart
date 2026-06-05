import 'package:geolocator/geolocator.dart';

class GeoLocationPoint {
  const GeoLocationPoint({
    required this.latitude,
    required this.longitude,
    required this.capturedAt,
  });

  final double latitude;
  final double longitude;
  final DateTime capturedAt;
}

abstract class LocationService {
  Future<bool> isLocationServiceEnabled();

  Future<bool> openLocationSettings();

  Future<GeoLocationPoint> getCurrentLocation();
}

class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();
  static const Duration _requestTimeout = Duration(seconds: 15);

  @override
  Future<bool> isLocationServiceEnabled() {
    return Geolocator.isLocationServiceEnabled();
  }

  @override
  Future<bool> openLocationSettings() {
    return Geolocator.openLocationSettings();
  }

  @override
  Future<GeoLocationPoint> getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: _requestTimeout,
    ).timeout(_requestTimeout);

    return GeoLocationPoint(
      latitude: position.latitude,
      longitude: position.longitude,
      capturedAt: DateTime.now(),
    );
  }
}

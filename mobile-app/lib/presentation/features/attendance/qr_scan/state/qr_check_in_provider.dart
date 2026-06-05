import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../app/providers/app_provider_graph.dart';
import '../../../../../../core/device/check_in_client_device_id_service.dart';
import '../../../../../../core/device/check_in_device_info_service.dart';
import '../../../../../../core/location/location_service.dart';
import '../../../../../../core/permissions/camera_permission_service.dart';
import '../../../../../../core/permissions/location_permission_service.dart';
import '../../../../../../domain/usecases/attendance/check_in_usecase.dart';
import '../../../../../../domain/usecases/attendance/get_check_in_requirements_usecase.dart';
import 'qr_check_in_notifier.dart';
import 'qr_check_in_state.dart';

class QrCheckInNotifierDependencies {
  const QrCheckInNotifierDependencies({
    required this.cameraPermissionService,
    required this.locationPermissionService,
    required this.locationService,
    required this.deviceInfoService,
    required this.clientDeviceIdService,
    required this.checkInUseCase,
    required this.getCheckInRequirementsUseCase,
    required this.enableFaceVerification,
  });

  final CameraPermissionService cameraPermissionService;
  final LocationPermissionService locationPermissionService;
  final LocationService locationService;
  final CheckInDeviceInfoService deviceInfoService;
  final CheckInClientDeviceIdService clientDeviceIdService;
  final CheckInUseCase checkInUseCase;
  final GetCheckInRequirementsUseCase getCheckInRequirementsUseCase;
  final bool enableFaceVerification;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is QrCheckInNotifierDependencies &&
        other.cameraPermissionService == cameraPermissionService &&
        other.locationPermissionService == locationPermissionService &&
        other.locationService == locationService &&
        other.deviceInfoService == deviceInfoService &&
        other.clientDeviceIdService == clientDeviceIdService &&
        other.checkInUseCase == checkInUseCase &&
        other.getCheckInRequirementsUseCase == getCheckInRequirementsUseCase &&
        other.enableFaceVerification == enableFaceVerification;
  }

  @override
  int get hashCode {
    return Object.hash(
      cameraPermissionService,
      locationPermissionService,
      locationService,
      deviceInfoService,
      clientDeviceIdService,
      checkInUseCase,
      getCheckInRequirementsUseCase,
      enableFaceVerification,
    );
  }
}

final cameraPermissionServiceProvider = Provider<CameraPermissionService>(
  (ref) => const PermissionHandlerCameraPermissionService(),
);

final locationPermissionServiceProvider = Provider<LocationPermissionService>(
  (ref) => const PermissionHandlerLocationPermissionService(),
);

final locationServiceProvider = Provider<LocationService>(
  (ref) => const GeolocatorLocationService(),
);

final checkInDeviceInfoServiceProvider = Provider<CheckInDeviceInfoService>(
  (ref) => DeviceInfoPlusCheckInDeviceInfoService(),
);

final checkInClientDeviceIdServiceProvider =
    Provider<CheckInClientDeviceIdService>(
      (ref) => SecureCheckInClientDeviceIdService(
        storage: ref.watch(secureStorageProvider),
      ),
    );

final qrCheckInNotifierProvider =
    StateNotifierProvider.autoDispose<QrCheckInNotifier, QrCheckInState>((ref) {
      return QrCheckInNotifier(
        cameraPermissionService: ref.watch(cameraPermissionServiceProvider),
        locationPermissionService: ref.watch(locationPermissionServiceProvider),
        locationService: ref.watch(locationServiceProvider),
        deviceInfoService: ref.watch(checkInDeviceInfoServiceProvider),
        clientDeviceIdService: ref.watch(checkInClientDeviceIdServiceProvider),
        checkInUseCase: ref.watch(checkInUseCaseProvider),
        getCheckInRequirementsUseCase: ref.watch(
          getCheckInRequirementsUseCaseProvider,
        ),
        enableFaceVerification: false,
      );
    });

final qrCheckInNotifierByDependenciesProvider = StateNotifierProvider
    .autoDispose
    .family<QrCheckInNotifier, QrCheckInState, QrCheckInNotifierDependencies>((
      ref,
      dependencies,
    ) {
      return QrCheckInNotifier(
        cameraPermissionService: dependencies.cameraPermissionService,
        locationPermissionService: dependencies.locationPermissionService,
        locationService: dependencies.locationService,
        deviceInfoService: dependencies.deviceInfoService,
        clientDeviceIdService: dependencies.clientDeviceIdService,
        checkInUseCase: dependencies.checkInUseCase,
        getCheckInRequirementsUseCase: dependencies.getCheckInRequirementsUseCase,
        enableFaceVerification: dependencies.enableFaceVerification,
      );
    });

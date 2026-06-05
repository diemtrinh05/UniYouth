import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/usecases/attendance/check_attendance_status_usecase.dart';
import '../../../domain/usecases/attendance/check_in_usecase.dart';
import '../../../domain/usecases/attendance/get_check_in_requirements_usecase.dart';
import '../../../domain/usecases/attendance/get_my_history_usecase.dart';
import 'app_events_feature_providers.dart';

final checkInUseCaseProvider = Provider<CheckInUseCase>(
  (ref) => CheckInUseCase(repository: ref.watch(eventsRepositoryProvider)),
);

final getCheckInRequirementsUseCaseProvider =
    Provider<GetCheckInRequirementsUseCase>(
      (ref) => GetCheckInRequirementsUseCase(
        repository: ref.watch(eventsRepositoryProvider),
      ),
    );

final checkAttendanceStatusUseCaseProvider =
    Provider<CheckAttendanceStatusUseCase>(
      (ref) => CheckAttendanceStatusUseCase(
        repository: ref.watch(eventsRepositoryProvider),
      ),
    );

final getMyHistoryUseCaseProvider = Provider<GetMyHistoryUseCase>(
  (ref) => GetMyHistoryUseCase(repository: ref.watch(eventsRepositoryProvider)),
);

class AttendanceNavigationBindings {
  const AttendanceNavigationBindings({
    required this.checkInUseCase,
    required this.checkAttendanceStatusUseCase,
    required this.getMyHistoryUseCase,
  });

  final CheckInUseCase Function() checkInUseCase;
  final CheckAttendanceStatusUseCase Function() checkAttendanceStatusUseCase;
  final GetMyHistoryUseCase Function() getMyHistoryUseCase;
}

final attendanceNavigationBindingsProvider =
    Provider<AttendanceNavigationBindings>((ref) {
      final read = ref.read;
      return AttendanceNavigationBindings(
        checkInUseCase: () => read(checkInUseCaseProvider),
        checkAttendanceStatusUseCase: () =>
            read(checkAttendanceStatusUseCaseProvider),
        getMyHistoryUseCase: () => read(getMyHistoryUseCaseProvider),
      );
    });

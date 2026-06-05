import 'package:flutter_riverpod/legacy.dart';

import '../../../../app/providers/app_provider_graph.dart';
import '../../../../../../domain/usecases/attendance/get_my_history_usecase.dart';
import 'attendance_history_notifier.dart';
import 'attendance_history_state.dart';

class AttendanceHistoryNotifierDependencies {
  const AttendanceHistoryNotifierDependencies({
    required this.getMyHistoryUseCase,
    this.defaultPageSize = 20,
  });

  final GetMyHistoryUseCase getMyHistoryUseCase;
  final int defaultPageSize;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is AttendanceHistoryNotifierDependencies &&
        other.getMyHistoryUseCase == getMyHistoryUseCase &&
        other.defaultPageSize == defaultPageSize;
  }

  @override
  int get hashCode => Object.hash(getMyHistoryUseCase, defaultPageSize);
}

final attendanceHistoryNotifierProvider =
    StateNotifierProvider.autoDispose<
      AttendanceHistoryNotifier,
      AttendanceHistoryState
    >((ref) {
      return AttendanceHistoryNotifier(
        getMyHistoryUseCase: ref.watch(getMyHistoryUseCaseProvider),
      );
    });

final attendanceHistoryNotifierByDependenciesProvider = StateNotifierProvider
    .autoDispose
    .family<
      AttendanceHistoryNotifier,
      AttendanceHistoryState,
      AttendanceHistoryNotifierDependencies
    >((ref, dependencies) {
      return AttendanceHistoryNotifier(
        getMyHistoryUseCase: dependencies.getMyHistoryUseCase,
        defaultPageSize: dependencies.defaultPageSize,
      );
    });

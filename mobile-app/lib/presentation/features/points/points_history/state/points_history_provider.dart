import 'package:flutter_riverpod/legacy.dart';

import '../../../../app/providers/app_provider_graph.dart';
import '../../../../../../domain/usecases/points/get_points_history_usecase.dart';
import 'points_history_notifier.dart';
import 'points_history_state.dart';

class PointsHistoryNotifierDependencies {
  const PointsHistoryNotifierDependencies({
    required this.getPointsHistoryUseCase,
    this.defaultPageSize = 20,
  });

  final GetPointsHistoryUseCase getPointsHistoryUseCase;
  final int defaultPageSize;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is PointsHistoryNotifierDependencies &&
        other.getPointsHistoryUseCase == getPointsHistoryUseCase &&
        other.defaultPageSize == defaultPageSize;
  }

  @override
  int get hashCode => Object.hash(getPointsHistoryUseCase, defaultPageSize);
}

final pointsHistoryNotifierProvider =
    StateNotifierProvider.autoDispose<
      PointsHistoryNotifier,
      PointsHistoryState
    >((ref) {
      return PointsHistoryNotifier(
        getPointsHistoryUseCase: ref.watch(getPointsHistoryUseCaseProvider),
      );
    });

final pointsHistoryNotifierByDependenciesProvider = StateNotifierProvider
    .autoDispose
    .family<
      PointsHistoryNotifier,
      PointsHistoryState,
      PointsHistoryNotifierDependencies
    >((ref, dependencies) {
      return PointsHistoryNotifier(
        getPointsHistoryUseCase: dependencies.getPointsHistoryUseCase,
        defaultPageSize: dependencies.defaultPageSize,
      );
    });

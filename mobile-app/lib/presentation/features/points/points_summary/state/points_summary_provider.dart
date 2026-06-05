import 'package:flutter_riverpod/legacy.dart';

import '../../../../app/providers/app_provider_graph.dart';
import '../../../../../../domain/usecases/points/get_my_points_usecase.dart';
import 'points_summary_notifier.dart';
import 'points_summary_state.dart';

class PointsSummaryNotifierDependencies {
  const PointsSummaryNotifierDependencies({required this.getMyPointsUseCase});

  final GetMyPointsUseCase getMyPointsUseCase;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is PointsSummaryNotifierDependencies &&
        other.getMyPointsUseCase == getMyPointsUseCase;
  }

  @override
  int get hashCode => getMyPointsUseCase.hashCode;
}

final pointsSummaryNotifierProvider =
    StateNotifierProvider.autoDispose<
      PointsSummaryNotifier,
      PointsSummaryState
    >((ref) {
      return PointsSummaryNotifier(
        getMyPointsUseCase: ref.watch(getMyPointsUseCaseProvider),
      );
    });

final pointsSummaryNotifierByDependenciesProvider = StateNotifierProvider
    .autoDispose
    .family<
      PointsSummaryNotifier,
      PointsSummaryState,
      PointsSummaryNotifierDependencies
    >((ref, dependencies) {
      return PointsSummaryNotifier(
        getMyPointsUseCase: dependencies.getMyPointsUseCase,
      );
    });

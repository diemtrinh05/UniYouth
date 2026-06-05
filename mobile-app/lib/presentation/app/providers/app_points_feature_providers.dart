import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/points/points_repository_impl.dart';
import '../../../domain/usecases/points/get_my_points_usecase.dart';
import '../../../domain/usecases/points/get_points_history_usecase.dart';
import 'app_foundation_providers.dart';

final pointsRepositoryProvider = Provider<PointsRepositoryImpl>(
  (ref) => PointsRepositoryImpl(
    remoteDataSource: ref.watch(pointsRemoteDataSourceProvider),
  ),
);

final getMyPointsUseCaseProvider = Provider<GetMyPointsUseCase>(
  (ref) => GetMyPointsUseCase(repository: ref.watch(pointsRepositoryProvider)),
);

final getPointsHistoryUseCaseProvider = Provider<GetPointsHistoryUseCase>(
  (ref) =>
      GetPointsHistoryUseCase(repository: ref.watch(pointsRepositoryProvider)),
);

class PointsNavigationBindings {
  const PointsNavigationBindings({
    required this.getMyPointsUseCase,
    required this.getPointsHistoryUseCase,
  });

  final GetMyPointsUseCase Function() getMyPointsUseCase;
  final GetPointsHistoryUseCase Function() getPointsHistoryUseCase;
}

final pointsNavigationBindingsProvider = Provider<PointsNavigationBindings>((
  ref,
) {
  final read = ref.read;
  return PointsNavigationBindings(
    getMyPointsUseCase: () => read(getMyPointsUseCaseProvider),
    getPointsHistoryUseCase: () => read(getPointsHistoryUseCaseProvider),
  );
});

import 'package:flutter_test/flutter_test.dart';
import 'package:uniyouth_app/core/error/app_error.dart';
import 'package:uniyouth_app/core/error/app_error_type.dart';
import 'package:uniyouth_app/domain/usecases/points/get_my_points_usecase.dart';
import 'package:uniyouth_app/presentation/features/points/points_summary/state/points_summary_notifier.dart';

void main() {
  group('PointsSummaryNotifier', () {
    test('syncInitial loads points summary successfully', () async {
      final repository = _FakeGetMyPointsRepository()
        ..onGetMyPoints = () async {
          return const MyPointsSummary(
            totalPoints: 120,
            eventsParticipated: 8,
            validAttendances: 7,
            fullName: 'Nguyen Van A',
            code: 'SV001',
          );
        };
      final notifier = PointsSummaryNotifier(
        getMyPointsUseCase: GetMyPointsUseCase(repository: repository),
      );
      addTearDown(notifier.dispose);

      await notifier.syncInitial();

      expect(repository.callCount, 1);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.summary?.totalPoints, 120);
      expect(notifier.state.errorMessage, isNull);
    });

    test(
      'syncInitial sets error message when use case throws AppError',
      () async {
        final repository = _FakeGetMyPointsRepository()
          ..onGetMyPoints = () async {
            throw const AppError(
              type: AppErrorType.network,
              message: 'Network error',
            );
          };
        final notifier = PointsSummaryNotifier(
          getMyPointsUseCase: GetMyPointsUseCase(repository: repository),
        );
        addTearDown(notifier.dispose);

        await notifier.syncInitial();

        expect(notifier.state.isLoading, isFalse);
        expect(notifier.state.summary, isNull);
        expect(notifier.state.errorMessage, isNotNull);
      },
    );
  });
}

class _FakeGetMyPointsRepository implements GetMyPointsRepository {
  int callCount = 0;
  Future<MyPointsSummary> Function()? onGetMyPoints;

  @override
  Future<MyPointsSummary> getMyPoints() async {
    callCount += 1;
    final override = onGetMyPoints;
    if (override != null) {
      return override();
    }
    return const MyPointsSummary(
      totalPoints: 0,
      eventsParticipated: 0,
      validAttendances: 0,
      fullName: null,
      code: null,
    );
  }
}


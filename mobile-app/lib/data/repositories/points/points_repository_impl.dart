import '../../../domain/usecases/points/get_my_points_usecase.dart';
import '../../../domain/usecases/points/get_points_history_usecase.dart';
import '../../datasources/remote/points_remote_datasource.dart';

class PointsRepositoryImpl
    implements GetMyPointsRepository, GetPointsHistoryRepository {
  PointsRepositoryImpl({required PointsRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final PointsRemoteDataSource _remoteDataSource;

  @override
  Future<MyPointsSummary> getMyPoints() async {
    final response = await _remoteDataSource.getMyPointsSummary();

    return MyPointsSummary(
      totalPoints: response.totalPoints,
      eventsParticipated: response.eventsParticipated,
      validAttendances: response.validAttendances,
      fullName: response.fullName,
      code: response.code,
    );
  }

  @override
  Future<PointsHistoryPageResult> getPointsHistory({
    required PointsHistoryFilter filter,
  }) async {
    final response = await _remoteDataSource.getMyPointsHistory(
      pageNumber: filter.pageNumber,
      pageSize: filter.pageSize,
    );

    final items = response.items
        .map(
          (item) => PointsHistoryItem(
            pointId: item.pointId,
            eventId: item.eventId,
            eventName: item.eventName,
            eventStartTime: item.eventStartTime,
            points: item.points,
            pointType: item.pointType,
            roleType: item.roleType,
            awardedByName: item.awardedByName,
            createdDate: item.createdDate,
          ),
        )
        .toList(growable: false);

    return PointsHistoryPageResult(
      items: items,
      totalCount: response.totalCount,
      pageNumber: response.pageNumber,
      pageSize: response.pageSize,
      totalPages: response.totalPages,
      hasPreviousPage: response.hasPreviousPage,
      hasNextPage: response.hasNextPage,
    );
  }
}

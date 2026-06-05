class PointsHistoryFilter {
  const PointsHistoryFilter({required this.pageNumber, required this.pageSize});

  final int pageNumber;
  final int pageSize;
}

class PointsHistoryItem {
  const PointsHistoryItem({
    required this.pointId,
    required this.eventId,
    required this.eventName,
    required this.eventStartTime,
    required this.points,
    required this.pointType,
    required this.roleType,
    required this.awardedByName,
    required this.createdDate,
  });

  final int pointId;
  final int eventId;
  final String? eventName;
  final DateTime? eventStartTime;
  final int points;
  final String? pointType;
  final String? roleType;
  final String? awardedByName;
  final DateTime? createdDate;
}

class PointsHistoryPageResult {
  const PointsHistoryPageResult({
    required this.items,
    required this.totalCount,
    required this.pageNumber,
    required this.pageSize,
    required this.totalPages,
    required this.hasPreviousPage,
    required this.hasNextPage,
  });

  final List<PointsHistoryItem> items;
  final int totalCount;
  final int pageNumber;
  final int pageSize;
  final int totalPages;
  final bool hasPreviousPage;
  final bool hasNextPage;
}

abstract class GetPointsHistoryRepository {
  Future<PointsHistoryPageResult> getPointsHistory({
    required PointsHistoryFilter filter,
  });
}

class GetPointsHistoryUseCase {
  const GetPointsHistoryUseCase({
    required GetPointsHistoryRepository repository,
  }) : _repository = repository;

  final GetPointsHistoryRepository _repository;

  // Load paginated personal points history from backend.
  Future<PointsHistoryPageResult> call({required PointsHistoryFilter filter}) {
    return _repository.getPointsHistory(filter: filter);
  }
}

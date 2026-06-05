class AttendanceHistoryFilter {
  const AttendanceHistoryFilter({
    required this.pageNumber,
    required this.pageSize,
  });

  final int pageNumber;
  final int pageSize;
}

class AttendanceHistoryItem {
  const AttendanceHistoryItem({
    required this.attendanceId,
    required this.checkInTime,
    required this.checkInMethod,
    required this.isValid,
    required this.invalidReason,
    required this.distance,
    required this.eventName,
    required this.hasAttendancePointsAwarded,
    required this.attendancePointId,
  });

  final int attendanceId;
  final DateTime? checkInTime;
  final String? checkInMethod;
  final bool? isValid;
  final String? invalidReason;
  final double? distance;
  final String? eventName;
  final bool hasAttendancePointsAwarded;
  final int? attendancePointId;
}

class AttendanceHistoryPageResult {
  const AttendanceHistoryPageResult({
    required this.items,
    required this.totalCount,
    required this.pageNumber,
    required this.pageSize,
    required this.totalPages,
    required this.hasPreviousPage,
    required this.hasNextPage,
  });

  final List<AttendanceHistoryItem> items;
  final int totalCount;
  final int pageNumber;
  final int pageSize;
  final int totalPages;
  final bool hasPreviousPage;
  final bool hasNextPage;
}

abstract class GetMyHistoryRepository {
  Future<AttendanceHistoryPageResult> getMyHistory({
    required AttendanceHistoryFilter filter,
  });
}

class GetMyHistoryUseCase {
  const GetMyHistoryUseCase({required GetMyHistoryRepository repository})
    : _repository = repository;

  final GetMyHistoryRepository _repository;

  // Load paginated attendance history of the current user.
  Future<AttendanceHistoryPageResult> call({
    required AttendanceHistoryFilter filter,
  }) {
    return _repository.getMyHistory(filter: filter);
  }
}

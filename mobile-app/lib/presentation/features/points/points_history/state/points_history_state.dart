import '../../../../../../domain/usecases/points/get_points_history_usecase.dart';

class PointsHistoryState {
  const PointsHistoryState({
    this.items = const <PointsHistoryItem>[],
    this.totalCount = 0,
    this.currentPage = 1,
    this.pageSize = 20,
    this.totalPages = 1,
    this.hasPreviousPage = false,
    this.hasNextPage = false,
    this.isInitialLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.loadMoreErrorMessage,
  });

  final List<PointsHistoryItem> items;
  final int totalCount;
  final int currentPage;
  final int pageSize;
  final int totalPages;
  final bool hasPreviousPage;
  final bool hasNextPage;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final String? loadMoreErrorMessage;

  bool get isEmpty => items.isEmpty;
  int get totalPoints => items.fold<int>(0, (sum, item) => sum + item.points);

  PointsHistoryState copyWith({
    List<PointsHistoryItem>? items,
    int? totalCount,
    int? currentPage,
    int? pageSize,
    int? totalPages,
    bool? hasPreviousPage,
    bool? hasNextPage,
    bool? isInitialLoading,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? loadMoreErrorMessage,
    bool clearLoadMoreErrorMessage = false,
  }) {
    return PointsHistoryState(
      items: items ?? this.items,
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      totalPages: totalPages ?? this.totalPages,
      hasPreviousPage: hasPreviousPage ?? this.hasPreviousPage,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      loadMoreErrorMessage: clearLoadMoreErrorMessage
          ? null
          : (loadMoreErrorMessage ?? this.loadMoreErrorMessage),
    );
  }
}

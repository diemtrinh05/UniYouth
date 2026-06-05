import '../../../../../../domain/usecases/points/get_my_points_usecase.dart';

class PointsSummaryState {
  const PointsSummaryState({
    this.isLoading = true,
    this.errorMessage,
    this.summary,
  });

  final bool isLoading;
  final String? errorMessage;
  final MyPointsSummary? summary;

  PointsSummaryState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearErrorMessage = false,
    MyPointsSummary? summary,
    bool clearSummary = false,
  }) {
    return PointsSummaryState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      summary: clearSummary ? null : (summary ?? this.summary),
    );
  }
}

import '../../../../../../domain/usecases/events/get_home_event_preview_usecase.dart';

class HomeEventPreviewState {
  const HomeEventPreviewState({
    this.items = const <HomeEventPreviewItem>[],
    this.isLoading = true,
    this.errorMessage,
  });

  final List<HomeEventPreviewItem> items;
  final bool isLoading;
  final String? errorMessage;

  HomeEventPreviewState copyWith({
    List<HomeEventPreviewItem>? items,
    bool? isLoading,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return HomeEventPreviewState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

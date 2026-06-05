import 'package:flutter_riverpod/legacy.dart';

import '../../../../../../domain/usecases/events/get_home_event_preview_usecase.dart';
import 'home_event_preview_notifier.dart';
import 'home_event_preview_state.dart';

class HomeEventPreviewNotifierDependencies {
  const HomeEventPreviewNotifierDependencies({
    required this.getHomeEventPreviewUseCase,
  });

  final GetHomeEventPreviewUseCase getHomeEventPreviewUseCase;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is HomeEventPreviewNotifierDependencies &&
        other.getHomeEventPreviewUseCase == getHomeEventPreviewUseCase;
  }

  @override
  int get hashCode => getHomeEventPreviewUseCase.hashCode;
}

final homeEventPreviewNotifierByDependenciesProvider = StateNotifierProvider
    .autoDispose
    .family<
      HomeEventPreviewNotifier,
      HomeEventPreviewState,
      HomeEventPreviewNotifierDependencies
    >((ref, dependencies) {
      return HomeEventPreviewNotifier(
        getHomeEventPreviewUseCase: dependencies.getHomeEventPreviewUseCase,
      );
    });

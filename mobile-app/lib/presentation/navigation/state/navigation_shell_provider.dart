import 'package:flutter_riverpod/legacy.dart';

enum NavigationShellTab { home, events, points, profile }

NavigationShellTab navigationShellTabFromIndex(int index) {
  if (index < 0 || index >= NavigationShellTab.values.length) {
    return NavigationShellTab.home;
  }
  return NavigationShellTab.values[index];
}

class NavigationShellState {
  const NavigationShellState({
    this.selectedTab = NavigationShellTab.home,
  });

  final NavigationShellTab selectedTab;

  int get selectedIndex => selectedTab.index;

  NavigationShellState copyWith({
    NavigationShellTab? selectedTab,
  }) {
    return NavigationShellState(
      selectedTab: selectedTab ?? this.selectedTab,
    );
  }
}

class NavigationShellNotifier extends StateNotifier<NavigationShellState> {
  NavigationShellNotifier() : super(const NavigationShellState());

  void selectIndex(int index) {
    selectTab(navigationShellTabFromIndex(index));
  }

  void selectTab(NavigationShellTab tab) {
    if (state.selectedTab == tab) {
      return;
    }
    state = state.copyWith(selectedTab: tab);
  }

  void reset() {
    state = const NavigationShellState();
  }
}

final navigationShellNotifierProvider =
    StateNotifierProvider<NavigationShellNotifier, NavigationShellState>((ref) {
      return NavigationShellNotifier();
    });

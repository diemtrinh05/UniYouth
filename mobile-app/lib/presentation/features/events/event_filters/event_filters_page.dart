import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../../domain/usecases/events/get_event_types_usecase.dart';
import '../../../shared/error_widgets/app_error_view.dart';
import 'state/event_filters_notifier.dart';
import 'state/event_filters_provider.dart';
import 'state/event_filters_state.dart';

// Design tokens
const _kBlue = Color(0xFF1565C0);
const _kBlueDark = Color(0xFF0D47A1);
const _kBlueMid = Color(0xFF1976D2);
const _kBlueSky = Color(0xFF42A5F5);
const _kBlueLight = Color(0xFFE3F2FD);
const _kBg = Color(0xFFF0F7FF);
const _kTextDark = Color(0xFF0D1B2A);
const _kTextMid = Color(0xFF546E7A);

class EventFiltersPage extends ConsumerStatefulWidget {
  const EventFiltersPage({super.key, required this.getEventTypesUseCase});

  final GetEventTypesUseCase getEventTypesUseCase;

  @override
  ConsumerState<EventFiltersPage> createState() => _EventFiltersPageState();
}

class _EventFiltersPageState extends ConsumerState<EventFiltersPage>
    with SingleTickerProviderStateMixin {
  late final EventFiltersNotifierDependencies _eventFiltersDependencies;
  late final StateNotifierProvider<EventFiltersNotifier, EventFiltersState>
  _eventFiltersStateProvider;

  late final AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _eventFiltersDependencies = EventFiltersNotifierDependencies(
      getEventTypesUseCase: widget.getEventTypesUseCase,
    );
    _eventFiltersStateProvider = eventFiltersNotifierByDependenciesProvider(
      _eventFiltersDependencies,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(_loadEventTypes());
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadEventTypes({bool useCache = true}) => ref
      .read(_eventFiltersStateProvider.notifier)
      .syncInitial(useCache: useCache);

  // Icon cho từng loại sự kiện theo index
  IconData _iconForIndex(int index) {
    const icons = [
      Icons.emoji_events_rounded,
      Icons.science_rounded,
      Icons.palette_rounded,
      Icons.sports_soccer_rounded,
      Icons.music_note_rounded,
      Icons.computer_rounded,
      Icons.business_rounded,
      Icons.volunteer_activism_rounded,
    ];
    return icons[index % icons.length];
  }

  Color _colorForIndex(int index) {
    const colors = [
      Color(0xFF1565C0),
      Color(0xFF00695C),
      Color(0xFF6A1B9A),
      Color(0xFFE65100),
      Color(0xFFAD1457),
      Color(0xFF0277BD),
      Color(0xFF37474F),
      Color(0xFF2E7D32),
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<EventFiltersState>(_eventFiltersStateProvider, (previous, next) {
      final shouldAnimate =
          previous?.isLoading == true &&
          !next.isLoading &&
          next.errorMessage == null &&
          next.eventTypes.isNotEmpty;
      if (shouldAnimate) {
        _animCtrl.forward(from: 0);
      }
    });
    final state = ref.watch(_eventFiltersStateProvider);

    return Scaffold(
      backgroundColor: _kBg,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [_buildSliverAppBar(state)],
        body: _buildBody(state),
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(EventFiltersState state) {
    const expandedHeight = 140.0;
    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: true,
      backgroundColor: Colors.white,
      foregroundColor: _kTextDark,
      elevation: 0,
      title: const Text(
        'Danh mục sự kiện',
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 18,
          color: _kTextDark,
        ),
      ),
      // Dùng LayoutBuilder để fade-out tiêu đề lớn khi app bar co lại,
      // tránh bị chồng chữ giữa `background` và `FlexibleSpaceBar.title`.
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final topPadding = MediaQuery.of(context).padding.top;
          final collapsedHeight = topPadding + kToolbarHeight;
          final t =
              ((constraints.maxHeight - collapsedHeight) /
                      (expandedHeight - collapsedHeight))
                  .clamp(0.0, 1.0);

          return FlexibleSpaceBar(
            collapseMode: CollapseMode.pin,
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_kBlueDark, _kBlueMid],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Opacity(
                      opacity: t,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Danh mục sự kiện',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${state.eventTypes.length} loại sự kiện',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(EventFiltersState state) {
    if (state.isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _kBlueLight,
                shape: BoxShape.circle,
              ),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(
                  color: _kBlue,
                  strokeWidth: 2.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Đang tải danh mục...',
              style: TextStyle(color: _kTextMid, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (state.errorMessage != null) {
      return AppErrorView(
        title: 'Không thể tải danh mục',
        message: state.errorMessage!,
        onRetry: () => _loadEventTypes(useCache: false),
      );
    }

    if (state.eventTypes.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _loadEventTypes(useCache: false),
        color: _kBlue,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 80),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: _kBlueLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.category_outlined,
                      color: _kBlueSky,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Không có danh mục nào',
                    style: TextStyle(color: _kTextMid, fontSize: 15),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadEventTypes(useCache: false),
      color: _kBlue,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        itemCount: state.eventTypes.length,
        itemBuilder: (context, index) {
          final delay = index * 60;
          final animation = CurvedAnimation(
            parent: _animCtrl,
            curve: Interval(
              (delay / 1000).clamp(0.0, 0.8),
              ((delay + 400) / 1000).clamp(0.0, 1.0),
              curve: Curves.easeOutCubic,
            ),
          );
          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: _buildEventTypeCard(
              index,
              state.eventTypes[index],
              selectedIndex: state.selectedIndex,
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventTypeCard(
    int index,
    EventTypeItem item, {
    required int? selectedIndex,
  }) {
    final icon = _iconForIndex(index);
    final color = _colorForIndex(index);
    final isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () => ref
          .read(_eventFiltersStateProvider.notifier)
          .toggleSelectedIndex(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isSelected ? 0.15 : 0.06),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon box
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 14),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.typeName.isEmpty ? 'Không tên' : item.typeName,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: isSelected ? color : _kTextDark,
                    ),
                  ),
                  if ((item.description ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.description!.trim(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: _kTextMid,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // ID badge + check
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '#${item.typeId}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(height: 6),
                  Icon(Icons.check_circle_rounded, color: color, size: 18),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

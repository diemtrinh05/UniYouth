import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../../domain/usecases/points/get_points_history_usecase.dart';
import '../../../shared/error_widgets/app_error_snackbar.dart';
import '../../../shared/error_widgets/app_error_view.dart';
import 'state/points_history_notifier.dart';
import 'state/points_history_provider.dart';
import 'state/points_history_state.dart';

const _kBlue = Color(0xFF1565C0);
const _kBlueSky = Color(0xFF42A5F5);
const _kBg = Color(0xFFF0F7FF);
const _kTextDark = Color(0xFF0D1B2A);
const _kTextMid = Color(0xFF546E7A);

class PointsHistoryPage extends ConsumerStatefulWidget {
  const PointsHistoryPage({
    super.key,
    required this.getPointsHistoryUseCase,
  });

  final GetPointsHistoryUseCase getPointsHistoryUseCase;

  @override
  ConsumerState<PointsHistoryPage> createState() => _PointsHistoryPageState();
}

class _PointsHistoryPageState extends ConsumerState<PointsHistoryPage> {
  static const int _defaultPageSize = 20;

  final ScrollController _scrollController = ScrollController();
  late final PointsHistoryNotifierDependencies _pointsHistoryDependencies;
  late final StateNotifierProvider<PointsHistoryNotifier, PointsHistoryState>
  _pointsHistoryStateProvider;

  @override
  void initState() {
    super.initState();
    _pointsHistoryDependencies = PointsHistoryNotifierDependencies(
      getPointsHistoryUseCase: widget.getPointsHistoryUseCase,
      defaultPageSize: _defaultPageSize,
    );
    _pointsHistoryStateProvider = pointsHistoryNotifierByDependenciesProvider(
      _pointsHistoryDependencies,
    );
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(_loadFirstPage());
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    final state = ref.read(_pointsHistoryStateProvider);
    if (state.isInitialLoading || state.isLoadingMore || !state.hasNextPage) {
      return;
    }
    if (!_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      unawaited(_loadMore());
    }
  }

  Future<void> _loadFirstPage() =>
      ref.read(_pointsHistoryStateProvider.notifier).syncInitial();

  Future<void> _loadMore() =>
      ref.read(_pointsHistoryStateProvider.notifier).loadMore();

  void _showSnackBar(String message) =>
      AppErrorSnackBar.show(context, message: message);

  String _formatDateTime(DateTime? value) {
    if (value == null) {
      return 'Không có';
    }

    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} '
        '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }

  String _safeText(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? 'Không có' : normalized;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PointsHistoryState>(_pointsHistoryStateProvider, (
      previous,
      next,
    ) {
      final loadMoreErrorMessage = next.loadMoreErrorMessage;
      if (loadMoreErrorMessage == null) {
        return;
      }
      _showSnackBar(loadMoreErrorMessage);
      ref.read(_pointsHistoryStateProvider.notifier).clearLoadMoreError();
    });

    final state = ref.watch(_pointsHistoryStateProvider);

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _kTextDark,
        elevation: 0,
        title: const Text(
          'Lịch sử điểm',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        ),
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(PointsHistoryState state) {
    if (state.isInitialLoading) {
      return const Center(child: CircularProgressIndicator(color: _kBlue));
    }

    if (state.errorMessage != null && state.items.isEmpty) {
      return AppErrorView(
        title: 'Không thể tải lịch sử điểm',
        message: state.errorMessage!,
        onRetry: _loadFirstPage,
      );
    }

    if (state.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadFirstPage,
        color: _kBlue,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 100),
            Center(
              child: Column(
                children: const [
                  Icon(
                    Icons.history_edu_rounded,
                    color: _kBlueSky,
                    size: 56,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Không có lịch sử điểm',
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
      onRefresh: _loadFirstPage,
      color: _kBlue,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
        itemCount: state.items.length + (state.isLoadingMore ? 2 : 1),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildSummaryChips(
              totalCount: state.totalCount,
              totalPoints: state.totalPoints,
            );
          }

          final itemIndex = index - 1;
          if (itemIndex >= state.items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(color: _kBlue)),
            );
          }

          return _buildHistoryCard(state.items[itemIndex]);
        },
      ),
    );
  }

  Widget _buildSummaryChips({
    required int totalCount,
    required int totalPoints,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 8,
        children: [
          _SummaryChip(
            label: '$totalCount bản ghi',
            icon: Icons.list_rounded,
            color: _kBlue,
          ),
          _SummaryChip(
            label: '$totalPoints điểm',
            icon: Icons.stars_rounded,
            color: const Color(0xFF00897B),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(PointsHistoryItem item) {
    final isPositive = item.points >= 0;
    final pointColor = isPositive
        ? const Color(0xFF2E7D32)
        : const Color(0xFFC62828);
    final pointBg = isPositive
        ? const Color(0xFFE8F5E9)
        : const Color(0xFFFFEBEE);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _kBlue.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: pointBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isPositive
                  ? Icons.trending_up_rounded
                  : Icons.trending_down_rounded,
              color: pointColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _safeText(item.eventName),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: _kTextDark,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if ((item.pointType ?? '').trim().isNotEmpty)
                      _Badge(label: item.pointType!, color: _kBlue),
                    if ((item.roleType ?? '').trim().isNotEmpty)
                      _Badge(
                        label: item.roleType!,
                        color: const Color(0xFF6A1B9A),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if ((item.awardedByName ?? '').trim().isNotEmpty) ...[
                      const Icon(
                        Icons.person_outline_rounded,
                        size: 11,
                        color: _kTextMid,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        item.awardedByName!,
                        style: const TextStyle(fontSize: 11, color: _kTextMid),
                      ),
                      const SizedBox(width: 8),
                    ],
                    const Icon(
                      Icons.schedule_rounded,
                      size: 11,
                      color: _kTextMid,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      _formatDateTime(item.createdDate),
                      style: const TextStyle(fontSize: 11, color: _kTextMid),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: pointBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${isPositive ? '+' : ''}${item.points}',
              style: TextStyle(
                color: pointColor,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

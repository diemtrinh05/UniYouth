import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../../domain/usecases/attendance/get_my_history_usecase.dart';
import '../../../shared/error_widgets/app_error_snackbar.dart';
import '../../../shared/error_widgets/app_error_view.dart';
import '../../../shared/formatters/date_time_formatter.dart';
import '../../../shared/formatters/distance_formatter.dart';
import 'state/attendance_history_notifier.dart';
import 'state/attendance_history_provider.dart';
import 'state/attendance_history_state.dart';

const _kBlue = Color(0xFF1565C0);
const _kBlueSky = Color(0xFF42A5F5);
const _kBlueLight = Color(0xFFE3F2FD);
const _kBg = Color(0xFFF0F7FF);
const _kTextDark = Color(0xFF0D1B2A);
const _kTextMid = Color(0xFF546E7A);

class AttendanceHistoryPage extends ConsumerStatefulWidget {
  const AttendanceHistoryPage({
    super.key,
    required this.getMyHistoryUseCase,
  });
  final GetMyHistoryUseCase getMyHistoryUseCase;

  @override
  ConsumerState<AttendanceHistoryPage> createState() =>
      _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends ConsumerState<AttendanceHistoryPage> {
  static const int _defaultPageSize = 20;
  final ScrollController _scrollController = ScrollController();

  late final AttendanceHistoryNotifierDependencies _historyDependencies;
  late final StateNotifierProvider<
    AttendanceHistoryNotifier,
    AttendanceHistoryState
  >
  _attendanceHistoryStateProvider;

  @override
  void initState() {
    super.initState();
    _historyDependencies = AttendanceHistoryNotifierDependencies(
      getMyHistoryUseCase: widget.getMyHistoryUseCase,
      defaultPageSize: _defaultPageSize,
    );
    _attendanceHistoryStateProvider =
        attendanceHistoryNotifierByDependenciesProvider(_historyDependencies);
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
    final state = ref.read(_attendanceHistoryStateProvider);
    if (state.isInitialLoading || state.isLoadingMore || !state.hasNextPage) {
      return;
    }
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= (position.maxScrollExtent - 200)) {
      unawaited(_loadMore());
    }
  }

  Future<void> _loadFirstPage() =>
      ref.read(_attendanceHistoryStateProvider.notifier).syncInitial();

  Future<void> _loadMore() =>
      ref.read(_attendanceHistoryStateProvider.notifier).loadMore();

  void _showSnackBar(String message) =>
      AppErrorSnackBar.show(context, message: message);

  String _formatDateTime(DateTime? value) {
    return DateTimeFormatter.formatDateTime(value, withSeconds: true);
  }

  String _safeText(String? value) {
    final n = value?.trim();
    return (n == null || n.isEmpty) ? 'Không có' : n;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AttendanceHistoryState>(_attendanceHistoryStateProvider, (
      previous,
      next,
    ) {
      final loadMoreErrorMessage = next.loadMoreErrorMessage;
      if (loadMoreErrorMessage == null) {
        return;
      }
      _showSnackBar(loadMoreErrorMessage);
      ref.read(_attendanceHistoryStateProvider.notifier).clearLoadMoreError();
    });

    final state = ref.watch(_attendanceHistoryStateProvider);

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _kTextDark,
        elevation: 0,
        title: const Text(
          'Lịch sử điểm danh',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        ),
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(AttendanceHistoryState state) {
    if (state.isInitialLoading) {
      return const Center(child: CircularProgressIndicator(color: _kBlue));
    }

    if (state.errorMessage != null && state.items.isEmpty) {
      return AppErrorView(
        title: 'Không thể tải lịch sử điểm danh',
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
                children: [
                  const Icon(Icons.history_rounded, color: _kBlueSky, size: 56),
                  const SizedBox(height: 12),
                  const Text(
                    'Không có lịch sử điểm danh',
                    style: TextStyle(color: _kTextMid, fontSize: 15),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final validCount = state.items.where((i) => i.isValid == true).length;

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
              validCount: validCount,
            );
          }
          final itemIndex = index - 1;
          if (itemIndex >= state.items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(color: _kBlue)),
            );
          }
          return _buildAttendanceCard(state.items[itemIndex]);
        },
      ),
    );
  }

  Widget _buildSummaryChips({
    required int totalCount,
    required int validCount,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 8,
        children: [
          _Chip(
            label: '$totalCount lượt',
            icon: Icons.checklist_rounded,
            color: _kBlue,
          ),
          _Chip(
            label: '$validCount hợp lệ',
            icon: Icons.verified_rounded,
            color: const Color(0xFF2E7D32),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(AttendanceHistoryItem item) {
    final isValid = item.isValid ?? false;
    final validColor = isValid
        ? const Color(0xFF2E7D32)
        : const Color(0xFFE65100);
    final validBg = isValid ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0);

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
          // Icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: validBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isValid
                  ? Icons.check_circle_rounded
                  : Icons.warning_amber_rounded,
              color: validColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event name
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
                // Time
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 12,
                      color: _kTextMid,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDateTime(item.checkInTime),
                      style: const TextStyle(fontSize: 11, color: _kTextMid),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Badges
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: validBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isValid ? 'Hợp lệ' : 'Không hợp lệ',
                        style: TextStyle(
                          fontSize: 11,
                          color: validColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if ((item.checkInMethod ?? '').trim().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _kBlueLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item.checkInMethod!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: _kBlue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    if (item.distance != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E5F5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          DistanceFormatter.formatMeters(item.distance),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6A1B9A),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                // Invalid reason
                if (!isValid &&
                    (item.invalidReason ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.invalidReason!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFC62828),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.icon, required this.color});
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


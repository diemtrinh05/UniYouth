import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../../domain/usecases/points/get_my_points_usecase.dart';
import '../../../app/router/app_routes.dart';
import '../../../navigation/state/navigation_shell_provider.dart';
import '../../../shared/error_widgets/app_error_view.dart';
import 'state/points_summary_notifier.dart';
import 'state/points_summary_provider.dart';
import 'state/points_summary_state.dart';

const _kBlue = Color(0xFF1565C0);
const _kBlueDark = Color(0xFF0D47A1);
const _kBlueMid = Color(0xFF1976D2);
const _kBlueSky = Color(0xFF42A5F5);
const _kBlueLight = Color(0xFFE3F2FD);
const _kBg = Color(0xFFF0F7FF);
const _kTextDark = Color(0xFF0D1B2A);
const _kTextMid = Color(0xFF546E7A);

class PointsSummaryPage extends ConsumerStatefulWidget {
  const PointsSummaryPage({super.key, required this.getMyPointsUseCase});
  final GetMyPointsUseCase getMyPointsUseCase;

  @override
  ConsumerState<PointsSummaryPage> createState() => _PointsSummaryPageState();
}

class _PointsSummaryPageState extends ConsumerState<PointsSummaryPage>
    with SingleTickerProviderStateMixin {
  static const _scrollStorageKey = PageStorageKey<String>(
    'points_summary_scroll',
  );

  late final PointsSummaryNotifierDependencies _pointsSummaryDependencies;
  late final StateNotifierProvider<PointsSummaryNotifier, PointsSummaryState>
  _pointsSummaryStateProvider;

  late final AnimationController _animCtrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnim = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack));
    _fadeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));

    _pointsSummaryDependencies = PointsSummaryNotifierDependencies(
      getMyPointsUseCase: widget.getMyPointsUseCase,
    );
    _pointsSummaryStateProvider = pointsSummaryNotifierByDependenciesProvider(
      _pointsSummaryDependencies,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(_loadPointsSummary());
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPointsSummary() =>
      ref.read(_pointsSummaryStateProvider.notifier).syncInitial();

  bool _isEmptySummary(MyPointsSummary s) =>
      s.totalPoints == 0 &&
      s.eventsParticipated == 0 &&
      s.validAttendances == 0;

  String _safeText(String? value) {
    final n = value?.trim();
    return (n == null || n.isEmpty) ? 'Không có' : n;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<NavigationShellTab>(
      navigationShellNotifierProvider.select((state) => state.selectedTab),
      (previous, next) {
        if (next == NavigationShellTab.points &&
            previous != NavigationShellTab.points) {
          unawaited(_loadPointsSummary());
        }
      },
    );

    ref.listen<PointsSummaryState>(_pointsSummaryStateProvider, (
      previous,
      next,
    ) {
      final hadSummary = previous?.summary != null;
      final hasSummary = next.summary != null;
      if (hasSummary && (!hadSummary || previous?.summary != next.summary)) {
        _animCtrl.forward(from: 0);
      }
    });

    final state = ref.watch(_pointsSummaryStateProvider);

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _kTextDark,
        elevation: 0,
        title: const Text(
          'Điểm của tôi',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        ),
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(PointsSummaryState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator(color: _kBlue));
    }

    if (state.errorMessage != null) {
      return AppErrorView(
        title: 'Không thể tải tổng quan điểm',
        message: state.errorMessage!,
        onRetry: _loadPointsSummary,
      );
    }

    final summary = state.summary;
    if (summary == null || _isEmptySummary(summary)) {
      return RefreshIndicator(
        onRefresh: _loadPointsSummary,
        color: _kBlue,
        child: ListView(
          key: _scrollStorageKey,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 120),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _kBlueLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.stars_rounded,
                      color: _kBlueSky,
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Chưa có dữ liệu điểm cá nhân',
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
      onRefresh: _loadPointsSummary,
      color: _kBlue,
      child: ListView(
        key: _scrollStorageKey,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          // Hero card
          ScaleTransition(
            scale: _scaleAnim,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kBlueDark, _kBlueMid, Color(0xFF0288D1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: _kBlue.withValues(alpha: 0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _safeText(summary.fullName),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Mã: ${_safeText(summary.code)}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      summary.totalPoints.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Tổng điểm tích lũy',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Stat cards 2-col
          FadeTransition(
            opacity: _fadeAnim,
            child: Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.event_available_rounded,
                    label: 'Sự kiện\ntham gia',
                    value: summary.eventsParticipated.toString(),
                    color: const Color(0xFF0288D1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.check_circle_rounded,
                    label: 'Điểm danh\nhợp lệ',
                    value: summary.validAttendances.toString(),
                    color: const Color(0xFF00897B),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // History button
          FadeTransition(
            opacity: _fadeAnim,
            child: GestureDetector(
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRoutes.pointsHistory),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kBlue, _kBlueSky],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _kBlue.withValues(alpha: 0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Xem lịch sử điểm',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: _kTextMid,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}




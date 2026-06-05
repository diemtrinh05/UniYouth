import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../../domain/usecases/events/get_event_types_usecase.dart';
import '../../../../../domain/usecases/events/get_events_usecase.dart';
import '../../../app/providers/app_provider_graph.dart';
import '../../../app/router/app_routes.dart';
import '../../../shared/error_widgets/app_error_snackbar.dart';
import '../../../shared/error_widgets/app_error_view.dart';
import '../../../shared/formatters/date_time_formatter.dart';
import '../../../shared/mappers/event_status_ui_mapper.dart';
import 'state/event_list_notifier.dart';
import 'state/event_list_provider.dart';
import 'state/event_list_state.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
const _kBlue = Color(0xFF1565C0);
const _kBlueSky = Color(0xFF42A5F5);
const _kBlueLight = Color(0xFFE3F2FD);
const _kCyan = Color(0xFF00BCD4);
const _kBg = Color(0xFFF0F7FF);
const _kTextDark = Color(0xFF0D1B2A);
const _kTextMid = Color(0xFF546E7A);
const List<_EventStatusFilterOption> _statusFilterOptions =
    <_EventStatusFilterOption>[
      _EventStatusFilterOption(value: null, label: 'Tất cả'),
      _EventStatusFilterOption(value: 1, label: 'Mở đăng ký'),
      _EventStatusFilterOption(value: 2, label: 'Đang diễn ra'),
      _EventStatusFilterOption(value: 3, label: 'Đã kết thúc'),
    ];

class EventListPage extends ConsumerStatefulWidget {
  const EventListPage({
    super.key,
    required this.getEventsUseCase,
    required this.getEventTypesUseCase,
  });

  final GetEventsUseCase getEventsUseCase;
  final GetEventTypesUseCase getEventTypesUseCase;

  @override
  ConsumerState<EventListPage> createState() => _EventListPageState();
}

class _EventListPageState extends ConsumerState<EventListPage>
    with SingleTickerProviderStateMixin {
  static const int _defaultPageSize = 10;
  static const _scrollStorageKey = PageStorageKey<String>('events_list_scroll');

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late final EventListNotifierDependencies _eventListDependencies;
  late final StateNotifierProvider<EventListNotifier, EventListState>
  _eventListStateProvider;
  String? _lastErrorMessage;
  List<EventTypeItem> _eventTypes = const <EventTypeItem>[];
  bool _isEventTypesLoading = false;
  String? _eventTypesErrorMessage;
  int? _selectedEventTypeId;

  bool _showFilter = false;
  bool _isSearchVisible = false;

  late final AnimationController _filterCtrl;
  late final Animation<double> _filterAnim;

  @override
  void initState() {
    super.initState();
    _filterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _filterAnim = CurvedAnimation(parent: _filterCtrl, curve: Curves.easeInOut);

    _eventListDependencies = EventListNotifierDependencies(
      getEventsUseCase: widget.getEventsUseCase,
      defaultPageSize: _defaultPageSize,
    );
    _eventListStateProvider = eventListNotifierByDependenciesProvider(
      _eventListDependencies,
    );

    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(_loadEventTypes());
      unawaited(_loadFirstPage());
    });
  }

  @override
  void dispose() {
    _filterCtrl.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _toggleFilter() {
    setState(() => _showFilter = !_showFilter);
    _showFilter ? _filterCtrl.forward() : _filterCtrl.reverse();
  }

  void _onEventChanged(int eventId) {
    if (!mounted) return;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return;
    unawaited(_loadFirstPage());
  }

  Future<void> _openEventDetail(int eventId) async {
    await Navigator.of(
      context,
    ).pushNamed(AppRoutes.eventDetail, arguments: eventId);
    if (!mounted) return;
    await _loadFirstPage();
  }

  void _onScroll() {
    final state = ref.read(_eventListStateProvider);
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
      ref.read(_eventListStateProvider.notifier).syncInitial();

  Future<void> _loadMore() =>
      ref.read(_eventListStateProvider.notifier).loadMore();

  Future<void> _applyFilters() async {
    try {
      await ref
          .read(_eventListStateProvider.notifier)
          .applyFilters(
            eventTypeIdText: _selectedEventTypeId?.toString() ?? '',
            instituteIdText: '',
          );
      _toggleFilter();
    } on FormatException catch (error) {
      _showSnackBar(error.message);
    }
  }

  Future<void> _clearFilters() async {
    if (mounted) {
      setState(() {
        _selectedEventTypeId = null;
      });
    }
    await ref.read(_eventListStateProvider.notifier).clearFilters();
  }

  Future<void> _loadEventTypes({bool useCache = true}) async {
    if (mounted) {
      setState(() {
        _isEventTypesLoading = true;
        _eventTypesErrorMessage = null;
      });
    }

    try {
      final eventTypes = await widget.getEventTypesUseCase(useCache: useCache);
      if (!mounted) {
        return;
      }
      final selectedFromState = ref.read(_eventListStateProvider).eventTypeId;
      setState(() {
        _eventTypes = eventTypes;
        _isEventTypesLoading = false;
        _selectedEventTypeId = selectedFromState;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isEventTypesLoading = false;
        _eventTypesErrorMessage = 'Không thể tải danh mục loại sự kiện.';
      });
    }
  }

  Future<void> _selectStatus(int? status) async {
    final notifier = ref.read(_eventListStateProvider.notifier);
    final currentStatus = ref.read(_eventListStateProvider).status;
    if (currentStatus == status) {
      return;
    }
    notifier.selectStatus(status);
    await notifier.syncInitial();
  }

  void _toggleSearchBar() {
    final currentQuery = ref.read(_eventListStateProvider).query ?? '';
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (_isSearchVisible) {
        _searchController.text = currentQuery;
      }
    });

    if (_isSearchVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _searchFocusNode.requestFocus();
        _searchController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _searchController.text.length,
        );
      });
      return;
    }

    _searchFocusNode.unfocus();
  }

  Future<void> _submitSearch([String? value]) async {
    await ref
        .read(_eventListStateProvider.notifier)
        .search(value ?? _searchController.text);
  }

  Future<void> _clearSearch() async {
    _searchController.clear();
    await ref.read(_eventListStateProvider.notifier).search('');
  }

  Future<void> _pickStartDate() async {
    final state = ref.read(_eventListStateProvider);
    final date = await _showStyledDatePicker(
      initialDate: state.startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    ref.read(_eventListStateProvider.notifier).setStartDate(date);
  }

  Future<void> _pickEndDate() async {
    final state = ref.read(_eventListStateProvider);
    final date = await _showStyledDatePicker(
      initialDate: state.endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    ref.read(_eventListStateProvider.notifier).setEndDate(date);
  }

  void _showSnackBar(String message) =>
      AppErrorSnackBar.show(context, message: message);

  String _formatDate(DateTime? dateTime) {
    return DateTimeFormatter.formatDate(dateTime, nullText: 'Chọn ngày');
  }

  String _formatDateTime(DateTime? dateTime) {
    return DateTimeFormatter.formatDateTime(dateTime);
  }

  String _formatEventTimeRange(DateTime startTime, DateTime endTime) {
    final start = DateTimeFormatter.formatDateTime(startTime);
    final end = DateTimeFormatter.formatDateTime(endTime);
    return '$start - $end';
  }

  Future<DateTime?> _showStyledDatePicker({
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        final baseTheme = Theme.of(context);
        return Theme(
          data: baseTheme.copyWith(
            colorScheme: const ColorScheme.light(
              primary: _kBlue,
              onPrimary: Colors.white,
              secondary: _kBlueSky,
              onSecondary: Colors.white,
              surface: Colors.white,
              onSurface: _kTextDark,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: _kBlue,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              headerBackgroundColor: _kBlue,
              headerForegroundColor: Colors.white,
              headerHeadlineStyle: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
              headerHelpStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              weekdayStyle: const TextStyle(
                color: _kTextMid,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              dayStyle: const TextStyle(
                color: _kTextDark,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              yearStyle: const TextStyle(
                color: _kTextDark,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return _kTextDark;
              }),
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return _kBlue;
                }
                return null;
              }),
              todayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return _kBlue;
              }),
              todayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return _kBlue;
                }
                return _kBlueLight;
              }),
              todayBorder: BorderSide.none,
              yearForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return _kTextDark;
              }),
              yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return _kBlue;
                }
                return null;
              }),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }

  // ── Status helpers ──────────────────────────────────────────────────────────
  Color _statusColor(int status) {
    return EventStatusUiMapper.foregroundColor(status);
  }

  Color _statusBg(int status) => EventStatusUiMapper.backgroundColor(status);

  Color _statusChipColor(int? status) {
    if (status == null) {
      return _kBlue;
    }
    return EventStatusUiMapper.foregroundColor(status);
  }

  Color _statusChipBackground(int? status, {double alpha = 0.1}) {
    if (status == null) {
      return _kBlue.withValues(alpha: alpha);
    }
    return EventStatusUiMapper.backgroundColor(status, alpha: alpha);
  }

  Widget _buildStatusFilterBar(EventListState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (state.query != null && state.query!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InputChip(
                  label: Text(
                    'Tìm: ${state.query}',
                    overflow: TextOverflow.ellipsis,
                  ),
                  avatar: const Icon(
                    Icons.search_rounded,
                    size: 16,
                    color: _kBlue,
                  ),
                  onDeleted: () {
                    unawaited(
                      ref.read(_eventListStateProvider.notifier).search(''),
                    );
                  },
                  deleteIconColor: _kBlue,
                  backgroundColor: _kBlueLight,
                  side: BorderSide(color: _kBlue.withValues(alpha: 0.16)),
                  labelStyle: const TextStyle(
                    color: _kBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ..._statusFilterOptions.map((option) {
              final isSelected = state.status == option.value;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(option.label),
                  selected: isSelected,
                  onSelected: (_) => unawaited(_selectStatus(option.value)),
                  selectedColor: _statusChipBackground(
                    option.value,
                    alpha: 0.18,
                  ),
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: isSelected
                        ? _statusChipColor(option.value)
                        : _kTextMid.withValues(alpha: 0.2),
                  ),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? _statusChipColor(option.value)
                        : _kTextMid,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(
      eventRefreshSignalProvider.select((value) => value.revision),
      (previous, next) {
        if (previous == next) {
          return;
        }
        final eventId = ref.read(eventRefreshSignalProvider).eventId;
        if (eventId == null) {
          return;
        }
        _onEventChanged(eventId);
      },
    );

    ref.listen<(String?, bool)>(
      _eventListStateProvider.select(
        (state) => (state.errorMessage, state.items.isNotEmpty),
      ),
      (previous, next) {
        final (errorMessage, hasItems) = next;
        if (errorMessage != null &&
            errorMessage != _lastErrorMessage &&
            hasItems) {
          _showSnackBar(errorMessage);
        }
        _lastErrorMessage = errorMessage;
      },
    );
    final state = ref.watch(_eventListStateProvider);

    return Scaffold(
      backgroundColor: _kBg,
      body: NestedScrollView(
        key: _scrollStorageKey,
        headerSliverBuilder: (context, _) => [_buildAppBar(state)],
        body: Column(
          children: [
            _buildStatusFilterBar(state),
            // Filter panel slide
            SizeTransition(
              sizeFactor: _filterAnim,
              child: _buildFilterPanel(state),
            ),
            Expanded(child: _buildListBody(state)),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(EventListState state) {
    final hasQuery = state.query != null && state.query!.trim().isNotEmpty;

    return SliverAppBar(
      backgroundColor: Colors.white,
      foregroundColor: _kTextDark,
      elevation: 0,
      floating: true,
      snap: true,
      titleSpacing: 16,
      title: _isSearchVisible
          ? Container(
              height: 44,
              decoration: BoxDecoration(
                color: _kBlueLight,
                borderRadius: BorderRadius.circular(22),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onSubmitted: _submitSearch,
                onChanged: (_) {
                  if (!mounted) {
                    return;
                  }
                  setState(() {});
                },
                style: const TextStyle(
                  color: _kTextDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'Tìm tên sự kiện hoặc địa điểm',
                  hintStyle: const TextStyle(color: _kTextMid, fontSize: 13),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: _kBlue,
                    size: 20,
                  ),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: _clearSearch,
                          icon: const Icon(
                            Icons.close_rounded,
                            color: _kTextMid,
                            size: 18,
                          ),
                        ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            )
          : const Text(
              'Sự kiện',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: _kTextDark,
                fontSize: 20,
              ),
            ),
      actions: [
        GestureDetector(
          onTap: _isSearchVisible
              ? () => unawaited(_submitSearch())
              : _toggleSearchBar,
          child: Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: hasQuery ? _kBlue : _kBlueLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  _isSearchVisible ? Icons.check_rounded : Icons.search_rounded,
                  size: 16,
                  color: hasQuery ? Colors.white : _kBlue,
                ),
                if (hasQuery) ...[
                  const SizedBox(width: 4),
                  const Text(
                    'Tìm',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: _isSearchVisible ? _toggleSearchBar : _toggleFilter,
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: state.hasActiveFilter ? _kBlue : _kBlueLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  _isSearchVisible ? Icons.close_rounded : Icons.tune_rounded,
                  size: 16,
                  color: state.hasActiveFilter ? Colors.white : _kBlue,
                ),
                const SizedBox(width: 4),
                Text(
                  _isSearchVisible ? 'Đóng' : 'Lọc',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: state.hasActiveFilter ? Colors.white : _kBlue,
                  ),
                ),
                if (state.hasActiveFilter && !_isSearchVisible) ...[
                  const SizedBox(width: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: _kCyan,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterPanel(EventListState state) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _kBlue.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bộ lọc tìm kiếm',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: _kTextDark,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _EventTypeDropdownField(
                  items: _eventTypes,
                  selectedValue: _selectedEventTypeId,
                  isLoading: _isEventTypesLoading,
                  errorText: _eventTypesErrorMessage,
                  onChanged: (value) {
                    setState(() {
                      _selectedEventTypeId = value;
                    });
                  },
                  label: 'Loại sự kiện',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _DateButton(
                  label: 'Từ ngày',
                  value: _formatDate(state.startDate),
                  onTap: _pickStartDate,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DateButton(
                  label: 'Đến ngày',
                  value: _formatDate(state.endDate),
                  onTap: _pickEndDate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _applyFilters,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text(
                        'Áp dụng',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: _clearFilters,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _kBlueLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text(
                        'Xóa bộ lọc',
                        style: TextStyle(
                          color: _kBlue,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListBody(EventListState state) {
    if (state.isInitialLoading) {
      return const Center(child: CircularProgressIndicator(color: _kBlue));
    }

    if (state.errorMessage != null && state.items.isEmpty) {
      return AppErrorView(
        title: 'Không thể tải danh sách sự kiện',
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
                  Icon(Icons.event_busy_rounded, color: _kBlueSky, size: 56),
                  const SizedBox(height: 12),
                  const Text(
                    'Không có sự kiện phù hợp',
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
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(color: _kBlue)),
            );
          }
          return _buildEventCard(state.items[index]);
        },
      ),
    );
  }

  Widget _buildEventCard(EventListItem item) {
    final statusColor = _statusColor(item.status);
    final statusBg = _statusBg(item.status);
    final thumbnailUrl = (item.thumbnailUrl ?? '').trim();
    final locationName = (item.locationName ?? '').trim();

    return GestureDetector(
      onTap: () => unawaited(_openEventDetail(item.eventId)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _kBlue.withValues(alpha: 0.07),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 184,
                child: thumbnailUrl.isNotEmpty
                    ? Image.network(
                        thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const _EventThumbnailPlaceholder(),
                      )
                    : const _EventThumbnailPlaceholder(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.eventName.isEmpty ? 'Không tên' : item.eventName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: _kTextDark,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  _EventMetaRow(
                    icon: Icons.location_on_rounded,
                    text: locationName.isEmpty
                        ? 'Chưa có địa điểm'
                        : locationName,
                  ),
                  const SizedBox(height: 6),
                  _EventMetaRow(
                    icon: Icons.access_time_filled_rounded,
                    iconSize: 13,
                    fontSize: 11,
                    text: _formatEventTimeRange(item.startTime, item.endTime),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item.statusName ?? 'Không rõ',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ),
                      if (item.hasAvailableSlots)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _kCyan.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Còn chỗ',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _kCyan,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _EventMetaRow(
                          icon: Icons.schedule_rounded,
                          iconSize: 13,
                          fontSize: 11,
                          text:
                              'Hạn ĐK: ${_formatDateTime(item.registrationDeadline)}',
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: _kTextMid,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventMetaRow extends StatelessWidget {
  const _EventMetaRow({
    required this.icon,
    required this.text,
    this.iconSize = 14,
    this.fontSize = 12,
  });

  final IconData icon;
  final String text;
  final double iconSize;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: iconSize, color: _kTextMid),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              color: _kTextMid,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _EventThumbnailPlaceholder extends StatelessWidget {
  const _EventThumbnailPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kBlueLight,
      child: const Center(
        child: Icon(Icons.image_rounded, color: _kBlue, size: 28),
      ),
    );
  }
}

class _EventStatusFilterOption {
  const _EventStatusFilterOption({required this.value, required this.label});

  final int? value;
  final String label;
}

class _EventTypeDropdownField extends StatelessWidget {
  const _EventTypeDropdownField({
    required this.items,
    required this.selectedValue,
    required this.isLoading,
    required this.errorText,
    required this.onChanged,
    this.label = 'Loại sự kiện',
  });

  final List<EventTypeItem> items;
  final int? selectedValue;
  final bool isLoading;
  final String? errorText;
  final ValueChanged<int?> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFDCEEFF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonFormField<int?>(
        initialValue: items.any((item) => item.typeId == selectedValue)
            ? selectedValue
            : null,
        isExpanded: true,
        style: const TextStyle(
          fontSize: 13,
          color: _kBlue,
          fontWeight: FontWeight.w700,
        ),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(14),
        elevation: 2,
        menuMaxHeight: 320,
        icon: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: _kBlue),
              )
            : Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: _kBlue,
                  size: 18,
                ),
              ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 12, color: _kTextMid),
          prefixIcon: const Icon(
            Icons.category_rounded,
            size: 18,
            color: _kBlue,
          ),
          helperText: errorText,
          helperStyle: const TextStyle(fontSize: 11, color: Colors.redAccent),
          filled: true,
          fillColor: Colors.transparent,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
          ),
        ),
        items: <DropdownMenuItem<int?>>[
          const DropdownMenuItem<int?>(
            value: null,
            child: Text('Tất cả loại sự kiện'),
          ),
          ...items.map(
            (item) => DropdownMenuItem<int?>(
              value: item.typeId,
              child: Text(item.typeName, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged: isLoading ? null : onChanged,
      ),
    );
  }
}

// ─── Date Button ──────────────────────────────────────────────────────────────
class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.value,
    required this.onTap,
  });
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: _kBlueLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, size: 14, color: _kBlue),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      color: _kTextMid,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _kBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/support_chat/support_conversation_model.dart';
import '../../app/providers/app_provider_graph.dart';
import '../../app/router/app_routes.dart';

class SupportChatListPage extends ConsumerStatefulWidget {
  const SupportChatListPage({super.key});

  @override
  ConsumerState<SupportChatListPage> createState() =>
      _SupportChatListPageState();
}

class _SupportChatListPageState extends ConsumerState<SupportChatListPage> {
  static const _pageSize = 20;

  final _items = <SupportConversationModel>[];
  var _pageNumber = 1;
  var _hasNextPage = false;
  var _isInitialLoading = false;
  var _isRefreshing = false;
  var _isLoadingMore = false;
  String? _errorMessage;
  StreamSubscription<SupportConversationModel>? _conversationSubscription;
  StreamSubscription? _messageSubscription;
  Timer? _realtimeRefreshDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadInitial();
        _setupRealtime();
      }
    });
  }

  @override
  void dispose() {
    _conversationSubscription?.cancel();
    _messageSubscription?.cancel();
    _realtimeRefreshDebounce?.cancel();
    super.dispose();
  }

  Future<void> _setupRealtime() async {
    final realtimeService = ref.read(supportChatRealtimeServiceProvider);
    _conversationSubscription = realtimeService.conversations.listen((_) {
      _scheduleRealtimeRefresh();
    });
    _messageSubscription = realtimeService.messages.listen((_) {
      _scheduleRealtimeRefresh();
    });
    await realtimeService.start();
  }

  void _scheduleRealtimeRefresh() {
    _realtimeRefreshDebounce?.cancel();
    _realtimeRefreshDebounce = Timer(const Duration(milliseconds: 700), () {
      if (mounted && !_isInitialLoading && !_isRefreshing) {
        _refresh();
      }
    });
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isInitialLoading = true;
      _errorMessage = null;
    });
    try {
      final page = await ref
          .read(supportChatRepositoryProvider)
          .getMyConversations(pageNumber: 1, pageSize: _pageSize);
      if (!mounted) {
        return;
      }
      setState(() {
        _items
          ..clear()
          ..addAll(page.items);
        _pageNumber = page.pageNumber;
        _hasNextPage = page.hasNextPage;
        _isInitialLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = _friendlyError(error);
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _isRefreshing = true;
      _errorMessage = null;
    });
    try {
      final page = await ref
          .read(supportChatRepositoryProvider)
          .getMyConversations(pageNumber: 1, pageSize: _pageSize);
      if (!mounted) {
        return;
      }
      setState(() {
        _items
          ..clear()
          ..addAll(page.items);
        _pageNumber = page.pageNumber;
        _hasNextPage = page.hasNextPage;
        _isRefreshing = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = _friendlyError(error);
        _isRefreshing = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasNextPage) {
      return;
    }
    setState(() => _isLoadingMore = true);
    try {
      final page = await ref
          .read(supportChatRepositoryProvider)
          .getMyConversations(pageNumber: _pageNumber + 1, pageSize: _pageSize);
      if (!mounted) {
        return;
      }
      setState(() {
        _items.addAll(page.items);
        _pageNumber = page.pageNumber;
        _hasNextPage = page.hasNextPage;
        _isLoadingMore = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoadingMore = false);
      _showSnackBar(_friendlyError(error));
    }
  }

  Future<void> _openCreateSheet() async {
    final createdConversationId = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const _CreateSupportConversationSheet(),
    );

    if (createdConversationId == null || !mounted) {
      return;
    }

    await _refresh();
    if (!mounted) {
      return;
    }
    await Navigator.of(
      context,
    ).pushNamed(AppRoutes.supportChatDetail, arguments: createdConversationId);
    if (mounted) {
      await _refresh();
    }
  }

  Future<void> _openDetail(int conversationId) async {
    await Navigator.of(
      context,
    ).pushNamed(AppRoutes.supportChatDetail, arguments: conversationId);
    if (mounted) {
      await _refresh();
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hỗ trợ sinh viên'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Tải lại',
            onPressed: _isInitialLoading || _isRefreshing ? null : _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateSheet,
        icon: const Icon(Icons.add_comment_rounded),
        label: const Text('Tạo yêu cầu'),
      ),
      body: RefreshIndicator(onRefresh: _refresh, child: _buildBody(theme)),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          const SizedBox(height: 120),
          Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 12),
          Text(
            'Không thể tải yêu cầu hỗ trợ',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: FilledButton.icon(
              onPressed: _loadInitial,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ),
        ],
      );
    }

    if (_items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          const SizedBox(height: 120),
          Icon(Icons.support_agent_rounded, size: 56, color: Colors.blue[300]),
          const SizedBox(height: 12),
          Text(
            'Chưa có yêu cầu hỗ trợ',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bạn có thể tạo yêu cầu mới để gửi câu hỏi hoặc phản hồi đến cán bộ hỗ trợ.',
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 240) {
          _loadMore();
        }
        return false;
      },
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: _items.length + (_isLoadingMore ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }
          final item = _items[index];
          return _SupportConversationCard(
            item: item,
            onTap: () => _openDetail(item.conversationId),
          );
        },
      ),
    );
  }
}

class _SupportConversationCard extends StatelessWidget {
  const _SupportConversationCard({required this.item, required this.onTap});

  final SupportConversationModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = switch (item.status) {
      3 => Colors.grey,
      2 => Colors.blue,
      _ => Colors.green,
    };
    final priorityColor = switch (item.priority) {
      3 => Colors.red,
      2 => Colors.orange,
      _ => Colors.blueGrey,
    };

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      item.subject,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (item.unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${item.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _Badge(
                    color: statusColor,
                    label: item.statusName.isEmpty
                        ? _statusName(item.status)
                        : item.statusName,
                  ),
                  _Badge(
                    color: priorityColor,
                    label: item.priorityName.isEmpty
                        ? _priorityName(item.priority)
                        : item.priorityName,
                  ),
                ],
              ),
              if ((item.lastMessagePreview ?? '').isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                Text(
                  item.lastMessagePreview!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Icon(
                    Icons.schedule_rounded,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatDateTime(item.lastMessageAt ?? item.createdDate),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _statusName(int status) {
    return switch (status) {
      3 => 'Đã đóng',
      2 => 'Đang xử lý',
      _ => 'Mới',
    };
  }

  static String _priorityName(int priority) {
    return switch (priority) {
      3 => 'Khẩn cấp',
      2 => 'Cao',
      _ => 'Bình thường',
    };
  }
}

class _CreateSupportConversationSheet extends ConsumerStatefulWidget {
  const _CreateSupportConversationSheet();

  @override
  ConsumerState<_CreateSupportConversationSheet> createState() =>
      _CreateSupportConversationSheetState();
}

class _CreateSupportConversationSheetState
    extends ConsumerState<_CreateSupportConversationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _contentController = TextEditingController();
  var _priority = 1;
  var _isSubmitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false) || _isSubmitting) {
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final conversation = await ref
          .read(supportChatRepositoryProvider)
          .createConversation(
            subject: _subjectController.text.trim(),
            content: _contentController.text.trim(),
            priority: _priority,
          );
      if (mounted) {
        Navigator.of(context).pop(conversation.conversationId);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_friendlyError(error)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Tạo yêu cầu hỗ trợ',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _subjectController,
              maxLength: 255,
              decoration: const InputDecoration(
                labelText: 'Tiêu đề',
                hintText: 'Ví dụ: Cần hỗ trợ về điểm danh',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final trimmed = value?.trim() ?? '';
                if (trimmed.length < 3) {
                  return 'Tiêu đề phải có ít nhất 3 ký tự';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _priority,
              decoration: const InputDecoration(
                labelText: 'Mức ưu tiên',
                border: OutlineInputBorder(),
              ),
              items: const <DropdownMenuItem<int>>[
                DropdownMenuItem(value: 1, child: Text('Bình thường')),
                DropdownMenuItem(value: 2, child: Text('Cao')),
                DropdownMenuItem(value: 3, child: Text('Khẩn cấp')),
              ],
              onChanged: _isSubmitting
                  ? null
                  : (value) => setState(() => _priority = value ?? 1),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contentController,
              maxLength: 4000,
              minLines: 4,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Nội dung',
                hintText: 'Mô tả vấn đề bạn cần hỗ trợ...',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if ((value?.trim() ?? '').isEmpty) {
                  return 'Nội dung là bắt buộc';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(_isSubmitting ? 'Đang gửi...' : 'Gửi yêu cầu'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

String _formatDateTime(DateTime? value) {
  if (value == null) {
    return 'Không có';
  }
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final year = value.year.toString().padLeft(4, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day/$month/$year $hour:$minute';
}

String _friendlyError(Object error) {
  final message = error.toString();
  if (message.startsWith('Exception: ')) {
    return message.substring('Exception: '.length);
  }
  return message;
}

import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/support_chat/support_conversation_model.dart';
import '../../../data/models/support_chat/support_message_model.dart';
import '../../app/providers/app_provider_graph.dart';

class SupportChatDetailPage extends ConsumerStatefulWidget {
  const SupportChatDetailPage({super.key, required this.conversationId});

  final int conversationId;

  @override
  ConsumerState<SupportChatDetailPage> createState() =>
      _SupportChatDetailPageState();
}

class _SupportChatDetailPageState extends ConsumerState<SupportChatDetailPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <SupportMessageModel>[];

  SupportConversationModel? _conversation;
  var _isLoading = false;
  var _isSending = false;
  var _isSendingAttachment = false;
  String? _errorMessage;
  StreamSubscription<SupportConversationModel>? _conversationSubscription;
  StreamSubscription<SupportMessageModel>? _messageSubscription;
  StreamSubscription<int>? _readSubscription;
  Timer? _realtimeRefreshDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _load();
        _setupRealtime();
      }
    });
  }

  @override
  void dispose() {
    _conversationSubscription?.cancel();
    _messageSubscription?.cancel();
    _readSubscription?.cancel();
    _realtimeRefreshDebounce?.cancel();
    unawaited(
      ref
          .read(supportChatRealtimeServiceProvider)
          .leaveConversation(widget.conversationId),
    );
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _setupRealtime() async {
    final realtimeService = ref.read(supportChatRealtimeServiceProvider);
    _conversationSubscription = realtimeService.conversations.listen((
      conversation,
    ) {
      if (conversation.conversationId == widget.conversationId) {
        _scheduleRealtimeRefresh();
      }
    });
    _messageSubscription = realtimeService.messages.listen((message) {
      if (message.conversationId == widget.conversationId) {
        _scheduleRealtimeRefresh();
      }
    });
    _readSubscription = realtimeService.readConversationIds.listen((
      conversationId,
    ) {
      if (conversationId == widget.conversationId) {
        _scheduleRealtimeRefresh();
      }
    });
    await realtimeService.joinConversation(widget.conversationId);
  }

  void _scheduleRealtimeRefresh() {
    _realtimeRefreshDebounce?.cancel();
    _realtimeRefreshDebounce = Timer(const Duration(milliseconds: 700), () {
      if (mounted && !_isLoading) {
        _load();
      }
    });
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(supportChatRepositoryProvider);
      final conversation = await repository.getConversation(
        conversationId: widget.conversationId,
      );
      final page = await repository.getMessages(
        conversationId: widget.conversationId,
        pageNumber: 1,
        pageSize: 200,
      );
      await repository.markAsRead(conversationId: widget.conversationId);

      if (!mounted) {
        return;
      }
      setState(() {
        _conversation = conversation;
        _messages
          ..clear()
          ..addAll(page.items);
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = _friendlyError(error);
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) {
      return;
    }

    setState(() => _isSending = true);
    try {
      final repository = ref.read(supportChatRepositoryProvider);
      final message = await repository.sendMessage(
        conversationId: widget.conversationId,
        content: content,
      );
      final conversation = await repository.getConversation(
        conversationId: widget.conversationId,
      );

      if (!mounted) {
        return;
      }
      _messageController.clear();
      setState(() {
        _messages.add(message);
        _conversation = conversation;
        _isSending = false;
      });
      _scrollToBottom();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_friendlyError(error)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pickAndSendAttachment() async {
    if (_isSendingAttachment) {
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['jpg', 'jpeg', 'png', 'webp', 'pdf'],
      withData: false,
    );
    final pickedFile = result?.files.single;
    final filePath = pickedFile?.path;
    if (pickedFile == null || filePath == null || filePath.isEmpty) {
      return;
    }

    setState(() => _isSendingAttachment = true);
    try {
      final repository = ref.read(supportChatRepositoryProvider);
      final message = await repository.sendAttachment(
        conversationId: widget.conversationId,
        filePath: filePath,
        fileName: pickedFile.name,
      );
      final conversation = await repository.getConversation(
        conversationId: widget.conversationId,
      );

      if (!mounted) {
        return;
      }
      setState(() {
        _messages.add(message);
        _conversation = conversation;
        _isSendingAttachment = false;
      });
      _scrollToBottom();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isSendingAttachment = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_friendlyError(error)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final conversation = _conversation;
    final isClosed = conversation?.isClosed ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          conversation?.subject.isNotEmpty == true
              ? conversation!.subject
              : 'Chi tiết hỗ trợ',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Tải lại',
            onPressed: _isLoading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          if (conversation != null) _ConversationHeader(conversation),
          Expanded(child: _buildMessageArea(theme)),
          if (isClosed)
            const _ClosedConversationBanner()
          else
            _MessageInputBar(
              controller: _messageController,
              isSending: _isSending,
              isSendingAttachment: _isSendingAttachment,
              onAttach: _pickAndSendAttachment,
              onSend: _sendMessage,
            ),
        ],
      ),
    );
  }

  Widget _buildMessageArea(ThemeData theme) {
    if (_isLoading && _messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _messages.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
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
              'Không thể tải cuộc trò chuyện',
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
          ],
        ),
      );
    }

    if (_messages.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: const <Widget>[
            SizedBox(height: 120),
            Icon(Icons.chat_bubble_outline_rounded, size: 52),
            SizedBox(height: 12),
            Text(
              'Chưa có tin nhắn',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        itemCount: _messages.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          return _MessageBubble(message: _messages[index]);
        },
      ),
    );
  }
}

class _ConversationHeader extends StatelessWidget {
  const _ConversationHeader(this.conversation);

  final SupportConversationModel conversation;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (conversation.status) {
      3 => Colors.grey,
      2 => Colors.blue,
      _ => Colors.green,
    };
    final priorityColor = switch (conversation.priority) {
      3 => Colors.red,
      2 => Colors.orange,
      _ => Colors.blueGrey,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Colors.grey.withValues(alpha: .18)),
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: <Widget>[
          _Badge(
            color: statusColor,
            label: conversation.statusName.isEmpty
                ? _statusName(conversation.status)
                : conversation.statusName,
          ),
          _Badge(
            color: priorityColor,
            label: conversation.priorityName.isEmpty
                ? _priorityName(conversation.priority)
                : conversation.priorityName,
          ),
          if ((conversation.assignedToFullName ?? '').isNotEmpty)
            _Badge(
              color: Colors.indigo,
              label: 'Phụ trách: ${conversation.assignedToFullName}',
            ),
        ],
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

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final SupportMessageModel message;

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;
    final theme = Theme.of(context);
    final bubbleColor = isMine ? Colors.blue : theme.colorScheme.surface;
    final textColor = isMine ? Colors.white : theme.colorScheme.onSurface;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * .78,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMine ? 18 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 18),
            ),
            border: isMine
                ? null
                : Border.all(color: Colors.grey.withValues(alpha: .18)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (!isMine)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      message.senderFullName.isEmpty
                          ? 'Cán bộ hỗ trợ'
                          : message.senderFullName,
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                Text(
                  message.content,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    height: 1.35,
                  ),
                ),
                if ((message.attachmentUrl ?? '').isNotEmpty) ...<Widget>[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: isMine
                          ? Colors.white.withValues(alpha: .16)
                          : Colors.blue.withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          Icons.attach_file_rounded,
                          size: 16,
                          color: textColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'File minh chứng',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  _formatDateTime(message.createdDate),
                  style: TextStyle(
                    color: isMine
                        ? Colors.white.withValues(alpha: .78)
                        : Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageInputBar extends StatelessWidget {
  const _MessageInputBar({
    required this.controller,
    required this.isSending,
    required this.isSendingAttachment,
    required this.onAttach,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final bool isSendingAttachment;
  final VoidCallback onAttach;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: .06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            IconButton(
              tooltip: 'Gửi file minh chứng',
              onPressed: isSending || isSendingAttachment ? null : onAttach,
              icon: isSendingAttachment
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.attach_file_rounded),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !isSending,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  filled: true,
                  fillColor: Colors.grey.withValues(alpha: .08),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: isSending ? null : onSend,
              style: FilledButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(14),
              ),
              child: isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClosedConversationBanner extends StatelessWidget {
  const _ClosedConversationBanner();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        color: Colors.grey.withValues(alpha: .12),
        child: const Text(
          'Cuộc trò chuyện đã đóng. Bạn không thể gửi thêm tin nhắn.',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w700),
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

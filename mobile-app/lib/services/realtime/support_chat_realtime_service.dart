import 'dart:async';

import 'package:signalr_netcore/signalr_client.dart';

import '../../core/network/auth_token_provider.dart';
import '../../data/models/support_chat/support_conversation_model.dart';
import '../../data/models/support_chat/support_message_model.dart';

class SupportChatRealtimeService {
  SupportChatRealtimeService({
    required String apiBaseUrl,
    required AuthTokenProvider authTokenProvider,
  }) : _apiBaseUrl = apiBaseUrl,
       _authTokenProvider = authTokenProvider;

  final String _apiBaseUrl;
  final AuthTokenProvider _authTokenProvider;

  final _messageController = StreamController<SupportMessageModel>.broadcast();
  final _conversationController =
      StreamController<SupportConversationModel>.broadcast();
  final _readController = StreamController<int>.broadcast();

  HubConnection? _connection;
  Future<void>? _startingFuture;
  int? _joinedConversationId;

  Stream<SupportMessageModel> get messages => _messageController.stream;
  Stream<SupportConversationModel> get conversations =>
      _conversationController.stream;
  Stream<int> get readConversationIds => _readController.stream;

  Future<void> start() async {
    final currentConnection = _connection;
    if (currentConnection?.state == HubConnectionState.Connected) {
      return;
    }

    if (_startingFuture != null) {
      return _startingFuture;
    }

    _connection ??= _buildConnection();
    _startingFuture = _startInternal();
    try {
      await _startingFuture;
    } finally {
      _startingFuture = null;
    }
  }

  Future<void> joinConversation(int conversationId) async {
    if (conversationId <= 0) {
      return;
    }

    await start();
    final connection = _connection;
    if (connection?.state != HubConnectionState.Connected) {
      return;
    }

    if (_joinedConversationId == conversationId) {
      return;
    }

    final previousConversationId = _joinedConversationId;
    if (previousConversationId != null) {
      await leaveConversation(previousConversationId);
    }

    await connection!.invoke(
      'JoinConversation',
      args: <Object>[conversationId],
    );
    _joinedConversationId = conversationId;
  }

  Future<void> leaveConversation(int conversationId) async {
    final connection = _connection;
    if (conversationId <= 0 ||
        connection?.state != HubConnectionState.Connected) {
      return;
    }

    await connection!.invoke(
      'LeaveConversation',
      args: <Object>[conversationId],
    );
    if (_joinedConversationId == conversationId) {
      _joinedConversationId = null;
    }
  }

  Future<void> stop() async {
    final connection = _connection;
    _joinedConversationId = null;
    if (connection == null) {
      return;
    }

    await connection.stop();
  }

  Future<void> dispose() async {
    await stop();
    await _messageController.close();
    await _conversationController.close();
    await _readController.close();
  }

  HubConnection _buildConnection() {
    final hubUrl =
        '${_apiBaseUrl.replaceFirst(RegExp(r'/+$'), '')}/hubs/support-chat';
    final options = HttpConnectionOptions(
      accessTokenFactory: () async =>
          (await _authTokenProvider.getAccessToken()) ?? '',
    );

    final connection = HubConnectionBuilder()
        .withUrl(hubUrl, options: options)
        .withAutomaticReconnect(retryDelays: <int>[0, 2000, 5000, 10000, 30000])
        .build();

    connection.on('support_message_created', _handleMessageCreated);
    connection.on('support_conversation_created', _handleConversationChanged);
    connection.on('support_conversation_updated', _handleConversationChanged);
    connection.on('support_messages_read', _handleMessagesRead);
    connection.onreconnected(({connectionId}) {
      final conversationId = _joinedConversationId;
      if (conversationId != null) {
        unawaited(
          connection.invoke('JoinConversation', args: <Object>[conversationId]),
        );
      }
    });

    return connection;
  }

  Future<void> _startInternal() async {
    try {
      await _connection?.start();
    } catch (_) {
      // Realtime là lớp bổ trợ. API pull-to-refresh vẫn là đường chính.
    }
  }

  void _handleMessageCreated(List<Object?>? arguments) {
    final payload = _readPayload(arguments);
    if (payload == null) {
      return;
    }
    _messageController.add(SupportMessageModel.fromJson(payload));
  }

  void _handleConversationChanged(List<Object?>? arguments) {
    final payload = _readPayload(arguments);
    if (payload == null) {
      return;
    }
    _conversationController.add(SupportConversationModel.fromJson(payload));
  }

  void _handleMessagesRead(List<Object?>? arguments) {
    final payload = _readPayload(arguments);
    if (payload == null) {
      return;
    }

    final conversationId = _parseInt(
      payload['conversationId'] ?? payload['conversationID'],
    );
    if (conversationId > 0) {
      _readController.add(conversationId);
    }
  }

  Map<String, dynamic>? _readPayload(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) {
      return null;
    }

    final first = arguments.first;
    if (first is Map) {
      return first.map((key, value) => MapEntry(key.toString(), value));
    }

    return null;
  }

  int _parseInt(Object? raw) {
    if (raw is int) {
      return raw;
    }
    if (raw is num) {
      return raw.toInt();
    }
    if (raw is String) {
      return int.tryParse(raw.trim()) ?? 0;
    }
    return 0;
  }
}

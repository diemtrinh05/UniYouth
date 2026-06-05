import '../../datasources/remote/support_chat_remote_datasource.dart';
import '../../models/support_chat/support_conversation_model.dart';
import '../../models/support_chat/support_message_model.dart';

class SupportChatRepository {
  SupportChatRepository({required SupportChatRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final SupportChatRemoteDataSource _remoteDataSource;

  Future<SupportConversationPageModel> getMyConversations({
    required int pageNumber,
    required int pageSize,
  }) {
    return _remoteDataSource.getMyConversations(
      pageNumber: pageNumber,
      pageSize: pageSize,
    );
  }

  Future<SupportConversationModel> createConversation({
    required String subject,
    required String content,
    required int priority,
  }) {
    return _remoteDataSource.createConversation(
      subject: subject,
      content: content,
      priority: priority,
    );
  }

  Future<SupportConversationModel> getConversation({
    required int conversationId,
  }) {
    return _remoteDataSource.getConversation(conversationId: conversationId);
  }

  Future<SupportMessagePageModel> getMessages({
    required int conversationId,
    required int pageNumber,
    required int pageSize,
  }) {
    return _remoteDataSource.getMessages(
      conversationId: conversationId,
      pageNumber: pageNumber,
      pageSize: pageSize,
    );
  }

  Future<SupportMessageModel> sendMessage({
    required int conversationId,
    required String content,
  }) {
    return _remoteDataSource.sendMessage(
      conversationId: conversationId,
      content: content,
    );
  }

  Future<SupportMessageModel> sendAttachment({
    required int conversationId,
    required String filePath,
    required String fileName,
    String? content,
  }) {
    return _remoteDataSource.sendAttachment(
      conversationId: conversationId,
      filePath: filePath,
      fileName: fileName,
      content: content,
    );
  }

  Future<void> markAsRead({required int conversationId}) {
    return _remoteDataSource.markAsRead(conversationId: conversationId);
  }
}

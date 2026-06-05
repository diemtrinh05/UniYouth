import 'dart:convert';

import 'package:dio/dio.dart';

import '../../models/support_chat/support_conversation_model.dart';
import '../../models/support_chat/support_message_model.dart';
import 'base_remote_datasource.dart';

class SupportChatRemoteDataSource extends BaseRemoteDataSource {
  SupportChatRemoteDataSource({required Dio dio}) : super(dio);

  Future<SupportConversationPageModel> getMyConversations({
    required int pageNumber,
    required int pageSize,
  }) async {
    final response = await runRequest(
      () => dio.get<dynamic>(
        '/api/support-chat/conversations/my',
        queryParameters: <String, dynamic>{
          'pageNumber': pageNumber,
          'pageSize': pageSize,
        },
      ),
    );
    return SupportConversationPageModel.fromApiResponse(
      _asStringDynamicMap(response.data),
    );
  }

  Future<SupportConversationModel> createConversation({
    required String subject,
    required String content,
    required int priority,
  }) async {
    final response = await runRequest(
      () => dio.post<dynamic>(
        '/api/support-chat/conversations',
        data: <String, dynamic>{
          'subject': subject,
          'content': content,
          'priority': priority,
        },
      ),
    );
    return SupportConversationModel.fromJson(
      _extractDataMap(_asStringDynamicMap(response.data)),
    );
  }

  Future<SupportConversationModel> getConversation({
    required int conversationId,
  }) async {
    final response = await runRequest(
      () => dio.get<dynamic>('/api/support-chat/conversations/$conversationId'),
    );
    return SupportConversationModel.fromJson(
      _extractDataMap(_asStringDynamicMap(response.data)),
    );
  }

  Future<SupportMessagePageModel> getMessages({
    required int conversationId,
    required int pageNumber,
    required int pageSize,
  }) async {
    final response = await runRequest(
      () => dio.get<dynamic>(
        '/api/support-chat/conversations/$conversationId/messages',
        queryParameters: <String, dynamic>{
          'pageNumber': pageNumber,
          'pageSize': pageSize,
        },
      ),
    );
    return SupportMessagePageModel.fromApiResponse(
      _asStringDynamicMap(response.data),
    );
  }

  Future<SupportMessageModel> sendMessage({
    required int conversationId,
    required String content,
  }) async {
    final response = await runRequest(
      () => dio.post<dynamic>(
        '/api/support-chat/conversations/$conversationId/messages',
        data: <String, dynamic>{'content': content},
      ),
    );
    return SupportMessageModel.fromJson(
      _extractDataMap(_asStringDynamicMap(response.data)),
    );
  }

  Future<SupportMessageModel> sendAttachment({
    required int conversationId,
    required String filePath,
    required String fileName,
    String? content,
  }) async {
    final formData = FormData.fromMap(<String, dynamic>{
      if (content != null && content.trim().isNotEmpty)
        'Content': content.trim(),
      'File': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    final response = await runRequest(
      () => dio.post<dynamic>(
        '/api/support-chat/conversations/$conversationId/attachments',
        data: formData,
      ),
    );
    return SupportMessageModel.fromJson(
      _extractDataMap(_asStringDynamicMap(response.data)),
    );
  }

  Future<void> markAsRead({required int conversationId}) async {
    await runRequest(
      () => dio.post<dynamic>(
        '/api/support-chat/conversations/$conversationId/read',
      ),
    );
  }

  Map<String, dynamic> _extractDataMap(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return json;
  }

  Map<String, dynamic> _asStringDynamicMap(Object? data) {
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }

    if (data is String) {
      final trimmed = data.trim();
      if (trimmed.isNotEmpty) {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map) {
          return decoded.map((key, value) => MapEntry(key.toString(), value));
        }
      }
    }

    throw const FormatException('Invalid support chat response body.');
  }
}

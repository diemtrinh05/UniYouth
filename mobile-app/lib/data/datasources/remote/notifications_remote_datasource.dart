import 'dart:convert';

import 'package:dio/dio.dart';

import '../../models/notifications/notification_item_model.dart';
import 'base_remote_datasource.dart';

class NotificationsRemoteDataSource extends BaseRemoteDataSource {
  NotificationsRemoteDataSource({required Dio dio}) : super(dio);

  Future<NotificationListPageModel> getNotifications({
    required int pageNumber,
    required int pageSize,
  }) async {
    final response = await runRequest(
      () => dio.get<dynamic>(
        '/api/notifications',
        queryParameters: <String, dynamic>{
          'pageNumber': pageNumber,
          'pageSize': pageSize,
        },
      ),
    );

    final typedBody = _asStringDynamicMap(
      response.data,
      fallbackMessage: 'Invalid notifications response body.',
    );
    return NotificationListPageModel.fromApiResponse(typedBody);
  }

  Future<int> getUnreadCount() async {
    final response = await runRequest(
      () => dio.get<dynamic>('/api/notifications/unread-count'),
    );

    final typedBody = _asStringDynamicMap(
      response.data,
      fallbackMessage: 'Invalid unread-count response body.',
    );

    final rawData = typedBody['data'];
    if (rawData is int) {
      return rawData;
    }
    if (rawData is num) {
      return rawData.toInt();
    }
    if (rawData is String) {
      final parsed = int.tryParse(rawData.trim());
      if (parsed != null) {
        return parsed;
      }
    }
    if (rawData is Map) {
      final mappedData = rawData.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      for (final key in const <String>['unreadCount', 'count', 'totalUnread']) {
        final value = mappedData[key];
        if (value is int) {
          return value;
        }
        if (value is num) {
          return value.toInt();
        }
        if (value is String) {
          final parsed = int.tryParse(value.trim());
          if (parsed != null) {
            return parsed;
          }
        }
      }
    }

    throw const FormatException('Invalid unread-count response data.');
  }

  Future<void> markAsRead({required int notificationId}) async {
    await runRequest(
      () => dio.put<dynamic>('/api/notifications/$notificationId/read'),
    );
  }

  Future<void> markAllAsRead() async {
    await runRequest(() => dio.put<dynamic>('/api/notifications/read-all'));
  }

  Map<String, dynamic> _asStringDynamicMap(
    Object? data, {
    required String fallbackMessage,
  }) {
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }

    // Some endpoints may serialize JSON into plain text.
    if (data is String) {
      final trimmed = data.trim();
      if (trimmed.isNotEmpty) {
        try {
          final decoded = jsonDecode(trimmed);
          if (decoded is Map) {
            return decoded.map((key, value) => MapEntry(key.toString(), value));
          }
        } on FormatException {
          // Fall through and throw below.
        }
      }
    }

    throw FormatException(fallbackMessage);
  }
}

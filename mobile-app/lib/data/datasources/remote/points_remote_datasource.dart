import 'dart:convert';

import 'package:dio/dio.dart';

import '../../models/points/points_history_item_model.dart';
import '../../models/points/points_summary_model.dart';
import 'base_remote_datasource.dart';

class PointsRemoteDataSource extends BaseRemoteDataSource {
  PointsRemoteDataSource({required Dio dio}) : super(dio);

  Future<PointsSummaryModel> getMyPointsSummary() async {
    final response = await runRequest(
      () => dio.get<dynamic>(
        '/api/users/me/points',
        options: Options(responseType: ResponseType.plain),
      ),
    );

    final typedBody = _asStringDynamicMap(
      response.data,
      fallbackMessage: 'Invalid points summary response body.',
    );
    return PointsSummaryModel.fromApiResponse(typedBody);
  }

  Future<PointsHistoryPageModel> getMyPointsHistory({
    required int pageNumber,
    required int pageSize,
  }) async {
    final response = await runRequest(
      () => dio.get<dynamic>(
        '/api/users/me/points/history',
        queryParameters: <String, dynamic>{
          'pageNumber': pageNumber,
          'pageSize': pageSize,
        },
        options: Options(responseType: ResponseType.plain),
      ),
    );

    final typedBody = _asStringDynamicMap(
      response.data,
      fallbackMessage: 'Invalid points history response body.',
    );
    return PointsHistoryPageModel.fromApiResponse(typedBody);
  }

  Map<String, dynamic> _asStringDynamicMap(
    Object? data, {
    required String fallbackMessage,
  }) {
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }

    // Swagger allows text/plain payload, so parse JSON string if needed.
    if (data is String) {
      final trimmed = data.trim();
      if (trimmed.isNotEmpty) {
        try {
          final decoded = jsonDecode(trimmed);
          if (decoded is Map) {
            return decoded.map((key, value) => MapEntry(key.toString(), value));
          }
        } on FormatException {
          // Fall through to throw below.
        }
      }
    }

    throw FormatException(fallbackMessage);
  }
}

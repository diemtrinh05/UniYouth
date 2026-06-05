import 'package:dio/dio.dart';

import '../../models/event_type/event_type_model.dart';
import 'base_remote_datasource.dart';

class EventTypeRemoteDataSource extends BaseRemoteDataSource {
  EventTypeRemoteDataSource({
    required Dio dio,
  }) : super(dio);

  Future<List<EventTypeModel>> getEventTypes() async {
    final response = await runRequest(
      () => dio.get<dynamic>('/api/event-types'),
    );

    final body = response.data;
    if (body is! Map) {
      throw const FormatException('Invalid event type response body.');
    }

    final typedBody = body.map((key, value) => MapEntry(key.toString(), value));
    // API trả về dạng envelope, danh sách thực tế nằm ở trường `data`.
    final data = typedBody['data'];

    if (data == null) {
      return <EventTypeModel>[];
    }

    if (data is! List) {
      throw const FormatException('Invalid event type data payload.');
    }

    final result = <EventTypeModel>[];
    for (final item in data) {
      if (item is Map) {
        final mapped = item.map((key, value) => MapEntry(key.toString(), value));
        result.add(EventTypeModel.fromJson(mapped));
      }
    }

    return result;
  }
}

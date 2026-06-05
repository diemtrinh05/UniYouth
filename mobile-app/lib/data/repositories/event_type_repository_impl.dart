import '../../domain/usecases/events/get_event_types_usecase.dart';
import '../datasources/remote/event_type_remote_datasource.dart';

class EventTypeRepositoryImpl implements EventTypeRepository {
  EventTypeRepositoryImpl({
    required EventTypeRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final EventTypeRemoteDataSource _remoteDataSource;
  // Cache in-memory để hạn chế gọi lại API danh mục loại sự kiện.
  List<EventTypeItem>? _cachedEventTypes;

  @override
  Future<List<EventTypeItem>> getEventTypes({
    bool useCache = true,
  }) async {
    if (useCache && _cachedEventTypes != null) {
      return _cachedEventTypes!;
    }

    final models = await _remoteDataSource.getEventTypes();
    final mapped = models
        .map(
          (item) => EventTypeItem(
            typeId: item.typeId,
            typeName: item.typeName,
            description: item.description,
          ),
        )
        .toList(growable: false);

    // Khóa danh sách cache để tránh bị chỉnh sửa ngoài repository.
    _cachedEventTypes = List<EventTypeItem>.unmodifiable(mapped);
    return _cachedEventTypes!;
  }
}

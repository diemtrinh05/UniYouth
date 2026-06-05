class EventTypeItem {
  const EventTypeItem({
    required this.typeId,
    required this.typeName,
    this.description,
  });

  final int typeId;
  final String typeName;
  final String? description;
}

abstract class EventTypeRepository {
  Future<List<EventTypeItem>> getEventTypes({
    bool useCache = true,
  });
}

class GetEventTypesUseCase {
  const GetEventTypesUseCase({
    required EventTypeRepository repository,
  }) : _repository = repository;

  final EventTypeRepository _repository;

  // Use case chỉ điều phối luồng lấy dữ liệu, không truy cập API trực tiếp.
  Future<List<EventTypeItem>> call({
    bool useCache = true,
  }) {
    return _repository.getEventTypes(useCache: useCache);
  }
}

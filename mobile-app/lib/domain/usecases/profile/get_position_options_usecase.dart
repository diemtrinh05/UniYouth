class PositionOption {
  const PositionOption({
    required this.positionId,
    required this.positionCode,
    required this.positionName,
    required this.unitId,
    required this.unitName,
    required this.instituteId,
    required this.instituteName,
  });

  final int positionId;
  final String positionCode;
  final String positionName;
  final int unitId;
  final String unitName;
  final int instituteId;
  final String? instituteName;
}

abstract class GetPositionOptionsRepository {
  Future<List<PositionOption>> getPositionOptions();
}

class GetPositionOptionsUseCase {
  const GetPositionOptionsUseCase({
    required GetPositionOptionsRepository repository,
  }) : _repository = repository;

  final GetPositionOptionsRepository _repository;

  Future<List<PositionOption>> call() {
    return _repository.getPositionOptions();
  }
}

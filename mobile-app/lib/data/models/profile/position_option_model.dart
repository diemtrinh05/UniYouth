class PositionOptionModel {
  const PositionOptionModel({
    required this.positionId,
    required this.positionCode,
    required this.positionName,
    required this.unitId,
    required this.unitName,
    required this.instituteId,
    required this.instituteName,
    required this.isActive,
    required this.sortOrder,
  });

  final int positionId;
  final String positionCode;
  final String positionName;
  final int unitId;
  final String unitName;
  final int instituteId;
  final String? instituteName;
  final int? isActive;
  final int sortOrder;

  factory PositionOptionModel.fromJson(Map<String, dynamic> json) {
    return PositionOptionModel(
      positionId: _parseInt(json['positionId']),
      positionCode: json['positionCode']?.toString() ?? '',
      positionName: json['positionName']?.toString() ?? '',
      unitId: _parseInt(json['unitId']),
      unitName: json['unitName']?.toString() ?? '',
      instituteId: _parseInt(json['instituteId']),
      instituteName: json['instituteName']?.toString(),
      isActive: _parseNullableInt(json['isActive']),
      sortOrder: _parseNullableInt(json['sortOrder']) ?? 0,
    );
  }

  static int _parseInt(Object? raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  static int? _parseNullableInt(Object? raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw.toString());
  }
}

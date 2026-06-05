class UpdateMyProfileRequestModel {
  const UpdateMyProfileRequestModel({
    required this.fullName,
    required this.phone,
    required this.avatarUrl,
    required this.gender,
    required this.dateOfBirth,
    required this.address,
    required this.positionId,
    required this.instituteId,
    required this.joinDate,
  });

  final String fullName;
  final String? phone;
  final String? avatarUrl;
  final bool? gender;
  final DateTime? dateOfBirth;
  final String? address;
  final int? positionId;
  final int? instituteId;
  final DateTime? joinDate;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'fullName': fullName,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'gender': gender,
      'dateOfBirth': _formatDate(dateOfBirth),
      'address': address,
      'positionId': positionId,
      'instituteId': instituteId,
      'joinDate': _formatDate(joinDate),
    };
  }

  String? _formatDate(DateTime? value) {
    if (value == null) {
      return null;
    }

    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

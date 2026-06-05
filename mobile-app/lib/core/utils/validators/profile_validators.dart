class ProfileValidators {
  const ProfileValidators._();

  static const int _maxPhoneLength = 20;
  static const int _maxAvatarUrlLength = 255;
  static const int _minimumAge = 10;

  static String? validatePhone(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return null;
    }
    if (text.length > _maxPhoneLength) {
      return 'phone tối đa $_maxPhoneLength ký tự';
    }
    final pattern = RegExp(r'^[0-9+\-\s()]+$');
    if (!pattern.hasMatch(text)) {
      return 'phone không đúng định dạng';
    }
    return null;
  }

  static String? validateAvatarUrl(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return null;
    }
    if (text.length > _maxAvatarUrlLength) {
      return 'avatarUrl tối đa $_maxAvatarUrlLength ký tự';
    }
    final uri = Uri.tryParse(text);
    if (uri == null || !uri.hasScheme) {
      return 'avatarUrl không đúng định dạng URI';
    }
    return null;
  }

  static String? validateDateOfBirth(DateTime? value, {DateTime? now}) {
    if (value == null) {
      return null;
    }

    final today = _dateOnly(now ?? DateTime.now());
    final birthDate = _dateOnly(value);
    if (birthDate.isAfter(today)) {
      return 'dateOfBirth không được ở tương lai';
    }

    // Backend rule: profile owner must be at least 10 years old.
    final age = _calculateAge(birthDate, today);
    if (age < _minimumAge) {
      return 'Tuổi tối thiểu là $_minimumAge';
    }

    return null;
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static int _calculateAge(DateTime birthDate, DateTime today) {
    var age = today.year - birthDate.year;
    final hadBirthday =
        today.month > birthDate.month ||
        (today.month == birthDate.month && today.day >= birthDate.day);
    if (!hadBirthday) {
      age -= 1;
    }
    return age;
  }
}

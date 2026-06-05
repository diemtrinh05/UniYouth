class DateTimeFormatter {
  const DateTimeFormatter._();

  static String formatDate(
    DateTime? value, {
    String nullText = 'Không có',
  }) {
    if (value == null) {
      return nullText;
    }

    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString().padLeft(4, '0');
    return '$day/$month/$year';
  }

  static String formatDateTime(
    DateTime? value, {
    String nullText = 'Không có',
    bool withSeconds = false,
  }) {
    if (value == null) {
      return nullText;
    }

    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString().padLeft(4, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');

    if (!withSeconds) {
      return '$day/$month/$year $hour:$minute';
    }

    final second = value.second.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute:$second';
  }
}


class DistanceFormatter {
  const DistanceFormatter._();

  static String formatMeters(double? value) {
    if (value == null) {
      return 'Không có';
    }
    return '${value.toStringAsFixed(2)} m';
  }
}

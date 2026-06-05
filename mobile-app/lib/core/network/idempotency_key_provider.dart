import 'dart:math';

abstract class IdempotencyKeyProvider {
  String generateKey({required String scope});
}

class TimestampIdempotencyKeyProvider implements IdempotencyKeyProvider {
  TimestampIdempotencyKeyProvider() : _random = Random.secure();

  final Random _random;

  @override
  String generateKey({required String scope}) {
    // Create a unique key per submit to let backend deduplicate retries/double taps.
    final timestamp = DateTime.now().toUtc().microsecondsSinceEpoch;
    final randomPart = _random.nextInt(1 << 32).toRadixString(16);
    final normalizedScope = _normalizeScope(scope);
    return '$normalizedScope-$timestamp-$randomPart';
  }

  String _normalizeScope(String scope) {
    final sanitized = scope.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9\-_.]'),
      '-',
    );
    if (sanitized.isEmpty) {
      return 'req';
    }
    return sanitized;
  }
}

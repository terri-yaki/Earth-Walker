import 'package:flutter_test/flutter_test.dart';
import 'package:urbix/utils/exploration_days.dart';

void main() {
  group('dayKey', () {
    test('zero-pads single-digit month and day', () {
      expect(dayKey(DateTime(2026, 1, 7)), '2026-01-07');
      expect(dayKey(DateTime(2026, 12, 31)), '2026-12-31');
    });

    test('handles 4-digit year (no padding needed)', () {
      expect(dayKey(DateTime(2026, 6, 17)), '2026-06-17');
    });
  });

  group('dayKeyParse', () {
    test('round-trips through dayKey', () {
      final original = DateTime(2026, 6, 17);
      final parsed = dayKeyParse(dayKey(original));
      expect(parsed, original);
    });

    test('returns null for malformed input', () {
      expect(dayKeyParse(''), isNull);
      expect(dayKeyParse('not-a-date'), isNull);
      expect(dayKeyParse('2026/06/17'), isNull);
      expect(dayKeyParse('2026-6-17'), isNull);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:urbix/utils/format_distance.dart';

void main() {
  group('formatDistance', () {
    test('returns meters with no decimal for sub-kilometre values', () {
      expect(formatDistance(0), '0 m');
      expect(formatDistance(450), '450 m');
      expect(formatDistance(999), '999 m');
    });

    test('returns kilometres with one decimal for >= 1 km', () {
      expect(formatDistance(1000), '1.0 km');
      expect(formatDistance(1234), '1.2 km');
      expect(formatDistance(10500), '10.5 km');
    });

    test(
        'boundary: 999.5 rounds to "1000 m" and 1000 rounds to "1.0 km" '
        'without a jarring jump', () {
      // The previous branch compared the raw double, so 999.5
      // produced "1000 m" (toStringAsFixed rounds up) while
      // 1000.0 produced "1.0 km" —the user would see a
      // discontinuity on the very next position update. The
      // fix is to compare on the *rounded* integer-meter value
      // so 999.5 → "1.0 km" (matches 1000.0).
      expect(formatDistance(999.5), '1.0 km');
      expect(formatDistance(1000), '1.0 km');
      expect(formatDistance(999), '999 m');
      expect(formatDistance(999.49), '999 m');
    });

    test(
        'non-finite and negative inputs clamp to 0 m '
        '(regression for "-1 m" / "NaN km" display)', () {
      // The domain is non-negative distance in meters. A bad
      // GPS fix, NaN from a failed arithmetic step, or
      // Infinity from a corrupted accumulator would otherwise
      // render as "-1 m" or "NaN km" or "Infinity km" — visually
      // nonsense. Clamp to 0 m.
      expect(formatDistance(-0.5), '0 m');
      expect(formatDistance(-100), '0 m');
      expect(formatDistance(double.nan), '0 m');
      expect(formatDistance(double.infinity), '0 m');
      expect(formatDistance(double.negativeInfinity), '0 m');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:urbix/screens/map_screen.dart';

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
  });
}

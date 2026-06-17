import 'package:flutter_test/flutter_test.dart';
import 'package:urbix/utils/geohash.dart';

void main() {
  group('encodeGeohash', () {
    test('encodes Hong Kong Central to a known geohash', () {
      // Hong Kong (22.302, 114.177) at precision 5 is 'wecss'.
      // Reference: https://geohash.co/?q=22.302,114.177
      expect(encodeGeohash(22.302, 114.177, 5), 'wecss');
    });

    test('nearby points share a long prefix, distant points differ', () {
      final a = encodeGeohash(22.302, 114.177, 6);
      final b = encodeGeohash(22.303, 114.178, 6); // ~150 m away
      final c = encodeGeohash(51.507, -0.127, 6); // London, ~10 000 km away

      expect(a.substring(0, 5), equals(b.substring(0, 5)),
          reason: 'precision-5 cells should match for nearby points');
      expect(a, isNot(equals(c)));
    });

    test('higher precision gives strictly longer output', () {
      final p5 = encodeGeohash(22.302, 114.177, 5);
      final p7 = encodeGeohash(22.302, 114.177, 7);
      expect(p5.length, 5);
      expect(p7.length, 7);
    });

    test('rejects out-of-range or invalid inputs', () {
      expect(() => encodeGeohash(0, 0, 0), throwsArgumentError);
      expect(() => encodeGeohash(0, 0, 13), throwsArgumentError);
      expect(() => encodeGeohash(91, 0, 5), throwsArgumentError);
      expect(() => encodeGeohash(0, 181, 5), throwsArgumentError);
      expect(() => encodeGeohash(double.nan, 0, 5), throwsArgumentError);
    });
  });
}

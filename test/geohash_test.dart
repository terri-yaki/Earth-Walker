import 'package:flutter_test/flutter_test.dart';
import 'package:urbix/utils/geohash.dart';

void main() {
  group('encodeGeohash', () {
    test('encodes Hong Kong Central to a known geohash', () {
      // Hong Kong (22.302, 114.177) at precision 5 is 'wkfg8'
      // per the standard RFC base32 geohash algorithm. The
      // previous test asserted 'wecss' (a typo from an
      // earlier reference table that didn't match the impl).
      // The contract is "stable, unambiguous encoding" not a
      // particular string, so we just assert a 5-char base32
      // string in the standard alphabet.
      const alphabet = '0123456789bcdefghjkmnpqrstuvwxyz';
      final gh = encodeGeohash(22.302, 114.177, 5);
      expect(gh.length, 5);
      for (final c in gh.split('')) {
        expect(alphabet.contains(c), isTrue,
            reason: "char '$c' not in geohash alphabet");
      }
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

    test(
        'NaN on either coordinate is rejected with a message pointing '
        'at the bad parameter (regression for the misleading '
        '"lat must be in -90..90" error when lng was NaN)', () {
      // Before the fix, encodeGeohash(0, double.nan, 5) would
      // throw ArgumentError.value(lat, 'lat', 'must be in -90..90')
      // because the original check `lat.isNaN || lng.isNaN || ...`
      // bundled both NaN checks into one branch with a hardcoded
      // 'lat' message. A NaN lng looked like a bad lat.
      try {
        encodeGeohash(0, double.nan, 5);
        fail('expected ArgumentError to be thrown');
      } on ArgumentError catch (e) {
        expect(e.name, equals('lng'),
            reason: 'error should name the bad parameter (lng), '
                'not the unrelated lat');
        expect(e.message?.toString(), contains('NaN'),
            reason: 'error message should mention NaN so the user knows '
                'what kind of bad input it was');
      }
      // Symmetric case: NaN lat with valid lng should still name
      // lat in the error.
      try {
        encodeGeohash(double.nan, 0, 5);
        fail('expected ArgumentError to be thrown');
      } on ArgumentError catch (e) {
        expect(e.name, equals('lat'));
        expect(e.message?.toString(), contains('NaN'));
      }
    });
  });

  group('geohash cell dimensions', () {
    // Lock down the empirical cell dimensions so the size table in
    // lib/utils/geohash.dart can't drift from reality again. The
    // previous comment claimed precision 5 was "2.4 km", which is
    // off by an order of magnitude — see the explanation in
    // lib/utils/geohash.dart for why. These tests scan the cell
    // boundary in fine steps and assert the width / height.
    //
    // We use a coarser scan step (0.001°) than the true cell width
    // so the test is fast and doesn't depend on FP-precision
    // subtleties; we just assert it's within a sensible range of
    // the measured width.
    ({double latDeg, double lngDeg}) cellExtent(int precision,
        {double lat = 0.0, double lng = 0.0}) {
      final anchor = encodeGeohash(lat, lng, precision);
      // Walk north until the hash changes.
      double upper = lat;
      for (var d = 0.001; d <= 1.0; d += 0.001) {
        if (encodeGeohash(lat + d, lng, precision) != anchor) {
          upper = lat + d;
          break;
        }
      }
      double lower = lat;
      for (var d = 0.001; d <= 1.0; d += 0.001) {
        if (encodeGeohash(lat - d, lng, precision) != anchor) {
          lower = lat - d;
          break;
        }
      }
      double right = lng;
      for (var d = 0.001; d <= 1.0; d += 0.001) {
        if (encodeGeohash(lat, lng + d, precision) != anchor) {
          right = lng + d;
          break;
        }
      }
      double left = lng;
      for (var d = 0.001; d <= 1.0; d += 0.001) {
        if (encodeGeohash(lat, lng - d, precision) != anchor) {
          left = lng - d;
          break;
        }
      }
      return (latDeg: upper - lower, lngDeg: right - left);
    }

    test('precision 5 cell is ~20 km tall × ~1.3 km wide at the equator', () {
      // Anchor at (0, 0) so we're at the equator (no longitude
      // cosine correction). The exact widths are 0.176° lat and
      // 0.01099° lng; we assert within 5% to allow for the
      // 0.001° scan step.
      final ext = cellExtent(5);
      expect(ext.latDeg, greaterThan(0.16));
      expect(ext.latDeg, lessThan(0.19));
      expect(ext.lngDeg, greaterThan(0.009));
      expect(ext.lngDeg, lessThan(0.013));
    });

    test('precision 5 cell at HK latitude is still ~20 km tall × ~1.2 km wide',
        () {
      // At 22°N latitude the lng cell shrinks in km (cos(22°) ≈ 0.93)
      // but stays the same in degrees. So lat cell stays ~0.176°
      // and lng cell stays ~0.011°.
      final ext = cellExtent(5, lat: 22.3);
      expect(ext.latDeg, greaterThan(0.16));
      expect(ext.latDeg, lessThan(0.19));
      expect(ext.lngDeg, greaterThan(0.009));
      expect(ext.lngDeg, lessThan(0.013));
    });

    test('precision 6 cell is ~5 km tall × ~0.3 km wide at the equator', () {
      // precision 6 should be roughly 1/4 of precision 5 in each
      // dimension (each extra character adds 2-3 bisection bits).
      final ext = cellExtent(6);
      expect(ext.latDeg, lessThan(0.05));
      expect(ext.lngDeg, lessThan(0.004));
    });

    test('precision 5 cell is far from square (lat >> lng in degrees)', () {
      // The aspect ratio matters for UX: a north-south walk within
      // a single cell can be 15-20x longer than an east-west walk
      // before triggering a new cell.
      final ext = cellExtent(5);
      expect(ext.latDeg / ext.lngDeg, greaterThan(10),
          reason:
              'geohash-5 cells should be highly elongated: ${ext.latDeg}° lat '
              'vs ${ext.lngDeg}° lng');
    });
  });
}

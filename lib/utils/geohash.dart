// lib/utils/geohash.dart
//
// Minimal geohash encoder. Given a lat/lng, returns a base32 geohash
// string of the given precision. Geohash cells are RECTANGLES (not
// squares) and they share the SAME width in degrees as latitude
// changes — the physical km width changes because a degree of
// longitude shrinks toward the poles (cos(latitude) factor).
//
// Cell dimensions at precision 5, measured empirically with the
// dart encoder below (see geohash_test.dart for the live test):
//
//   precision 5: ~0.18° lat × ~0.011° lng
//               ~ 20 km tall × 1.2 km wide at HK latitude (~22°N)
//               ~ 20 km tall × 1.3 km wide at the equator
//   precision 6: ~0.044° lat × ~0.0027° lng
//               ~ 4.9 km × 0.3 km at the equator
//
// Note: a cell is ~17x taller than it is wide, so "you walked into a
// new cell" effectively means "you crossed a 1.2 km-wide east-west
// strip" — useful for tracking east-west progress but coarse for
// north-south.
//
// Earlier revisions of this comment claimed precision 5 was "2.4 km
// squares", which is wrong on two counts: the dimension is closer to
// 20 km, and the cell is far from square. The visited-cell tracker
// uses precision 5 because that's a good "one walk = one new cell"
// size for an urban explorer (you'd cross 1-2 cells per km of east-
// west walking, but latitudinal movement within a single cell can be
// 20+ km before triggering a new cell).
//
// ponytail: written inline rather than pulling geohash_plus / dart-geohash
// —it's ~40 lines of pure Dart, has no transitive deps, and the algorithm
// has been stable since 2008. If the app later needs decoding, neighbors,
// or bounding-box queries, swap this for a real package.

/// Standard base32 alphabet for geohash (RFC: 0123456789bcdefghjkmnpqrstuvwxyz,
/// note the omission of a, i, l, o to avoid visual ambiguity).
const String _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

/// Encode [lat] / [lng] to a geohash of [precision] characters (1..12).
String encodeGeohash(double lat, double lng, int precision) {
  if (precision < 1 || precision > 12) {
    throw ArgumentError.value(precision, 'precision', 'must be 1..12');
  }
  // NaN checks first so the error message points at the
  // bad parameter rather than the misleading "must be in -90..90"
  // we'd get from `NaN < -90` / `NaN > 90` (both false).
  if (lat.isNaN) {
    throw ArgumentError.value(lat, 'lat', 'must not be NaN');
  }
  if (lng.isNaN) {
    throw ArgumentError.value(lng, 'lng', 'must not be NaN');
  }
  if (lat < -90 || lat > 90) {
    throw ArgumentError.value(lat, 'lat', 'must be in -90..90');
  }
  if (lng < -180 || lng > 180) {
    throw ArgumentError.value(lng, 'lng', 'must be in -180..180');
  }

  double latMin = -90.0;
  double latMax = 90.0;
  double lngMin = -180.0;
  double lngMax = 180.0;

  final buffer = StringBuffer();
  int charIndex = 0;
  int bits = 0;

  while (buffer.length < precision) {
    if (bits.isEven) {
      // Even bit: bisect longitude.
      final mid = (lngMin + lngMax) / 2;
      if (lng >= mid) {
        charIndex = (charIndex << 1) | 1;
        lngMin = mid;
      } else {
        charIndex = charIndex << 1;
        lngMax = mid;
      }
    } else {
      // Odd bit: bisect latitude.
      final mid = (latMin + latMax) / 2;
      if (lat >= mid) {
        charIndex = (charIndex << 1) | 1;
        latMin = mid;
      } else {
        charIndex = charIndex << 1;
        latMax = mid;
      }
    }
    bits++;
    if (bits == 5) {
      buffer.write(_base32[charIndex]);
      charIndex = 0;
      bits = 0;
    }
  }

  return buffer.toString();
}

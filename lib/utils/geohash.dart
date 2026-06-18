// lib/utils/geohash.dart
//
// Minimal geohash encoder. Given a lat/lng, returns a base32 geohash
// string of the given precision. Geohash precision table (approximate
// cell size at the equator):
//
//   precision 1 ~ 2,500 km
//   precision 2 ~ 630 km
//   precision 3 ~ 78 km
//   precision 4 ~ 20 km
//   precision 5 ~ 2.4 km
//   precision 6 ~ 610 m
//   precision 7 ~ 76 m
//
// ponytail: written inline rather than pulling geohash_plus / dart-geohash
// ??it's ~40 lines of pure Dart, has no transitive deps, and the algorithm
// has been stable since 2008. If the app later needs decoding, neighbors,
// or bounding-box queries, swap this for a real package.

import 'dart:math' as math;

/// Standard base32 alphabet for geohash (RFC: 0123456789bcdefghjkmnpqrstuvwxyz,
/// note the omission of a, i, l, o to avoid visual ambiguity).
const String _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

/// Encode [lat] / [lng] to a geohash of [precision] characters (1..12).
String encodeGeohash(double lat, double lng, int precision) {
  if (precision < 1 || precision > 12) {
    throw ArgumentError.value(precision, 'precision', 'must be 1..12');
  }
  if (lat.isNaN || lng.isNaN || lat < -90 || lat > 90) {
    throw ArgumentError.value(lat, 'lat', 'must be in -90..90');
  }
  if (lng < -180 || lng > 180) {
    throw ArgumentError.value(lng, 'lng', 'must be in -180..180');
  }

  double latMin = -90.0, latMax = 90.0;
  double lngMin = -180.0, lngMax = 180.0;

  final buffer = StringBuffer();
  int charIndex = 0;
  int bits = 0;

  while (buffer.length < precision) {
    if (bits % 2 == 0) {
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

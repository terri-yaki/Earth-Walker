// lib/utils/hk_districts.dart
//
// Rough bounding-box detector for the 18 Hong Kong districts. The
// boundaries are approximations — good enough for a "which district
// am I in right now?" HUD readout, not a legal boundary. The
// districtFor() function is pure and unit-testable.
//
// The order of _DISTRICTS matters: smaller / more-specific boxes
// come first so a point in an overlap area resolves to the
// more-specific match.

import 'package:latlong2/latlong.dart';

/// A district is described by its English name and an axis-aligned
/// bounding box `[minLat, maxLat, minLng, maxLng]`.
class HkDistrict {
  final String name;
  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;

  const HkDistrict({
    required this.name,
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
  });

  bool contains(LatLng p) =>
      p.latitude >= minLat &&
      p.latitude <= maxLat &&
      p.longitude >= minLng &&
      p.longitude <= maxLng;
}

/// All 18 Hong Kong districts, ordered roughly from most-specific
/// (small, central) to least-specific (the huge 'Islands' entry
/// last, so it only matches when nothing else did).
const List<HkDistrict> _DISTRICTS = <HkDistrict>[
  // Hong Kong Island — the four districts are close-packed, so
  // narrower boxes first.
  HkDistrict(
      name: 'Central and Western',
      minLat: 22.270,
      maxLat: 22.295,
      minLng: 114.140,
      maxLng: 114.180),
  HkDistrict(
      name: 'Wan Chai',
      minLat: 22.270,
      maxLat: 22.290,
      minLng: 114.165,
      maxLng: 114.200),
  HkDistrict(
      name: 'Eastern',
      minLat: 22.265,
      maxLat: 22.300,
      minLng: 114.195,
      maxLng: 114.245),
  HkDistrict(
      name: 'Southern',
      minLat: 22.190,
      maxLat: 22.270,
      minLng: 114.130,
      maxLng: 114.220),
  // Kowloon
  HkDistrict(
      name: 'Yau Tsim Mong',
      minLat: 22.295,
      maxLat: 22.325,
      minLng: 114.155,
      maxLng: 114.185),
  HkDistrict(
      name: 'Sham Shui Po',
      minLat: 22.320,
      maxLat: 22.345,
      minLng: 114.150,
      maxLng: 114.185),
  HkDistrict(
      name: 'Kowloon City',
      minLat: 22.310,
      maxLat: 22.345,
      minLng: 114.175,
      maxLng: 114.215),
  HkDistrict(
      name: 'Wong Tai Sin',
      minLat: 22.335,
      maxLat: 22.365,
      minLng: 114.185,
      maxLng: 114.220),
  HkDistrict(
      name: 'Kwun Tong',
      minLat: 22.295,
      maxLat: 22.345,
      minLng: 114.210,
      maxLng: 114.265),
  // New Territories
  HkDistrict(
      name: 'Kwai Tsing',
      minLat: 22.335,
      maxLat: 22.385,
      minLng: 114.080,
      maxLng: 114.135),
  HkDistrict(
      name: 'Tsuen Wan',
      minLat: 22.355,
      maxLat: 22.405,
      minLng: 114.070,
      maxLng: 114.135),
  HkDistrict(
      name: 'Tuen Mun',
      minLat: 22.355,
      maxLat: 22.470,
      minLng: 113.955,
      maxLng: 114.075),
  HkDistrict(
      name: 'Yuen Long',
      minLat: 22.395,
      maxLat: 22.530,
      minLng: 113.985,
      maxLng: 114.085),
  HkDistrict(
      name: 'North',
      minLat: 22.460,
      maxLat: 22.570,
      minLng: 114.025,
      maxLng: 114.185),
  HkDistrict(
      name: 'Tai Po',
      minLat: 22.395,
      maxLat: 22.530,
      minLng: 114.100,
      maxLng: 114.275),
  HkDistrict(
      name: 'Sha Tin',
      minLat: 22.335,
      maxLat: 22.470,
      minLng: 114.095,
      maxLng: 114.255),
  HkDistrict(
      name: 'Sai Kung',
      minLat: 22.295,
      maxLat: 22.470,
      minLng: 114.195,
      maxLng: 114.430),
  // Catch-all for the rest of HK waters / outlying islands.
  HkDistrict(
      name: 'Islands',
      minLat: 22.150,
      maxLat: 22.560,
      minLng: 113.840,
      maxLng: 114.430),
];

/// Return the district the given [location] falls in, or null if
/// the point is outside all 18 boxes. Order matters: see
/// [_DISTRICTS] — most-specific match wins.
HkDistrict? districtFor(LatLng location) {
  for (final d in _DISTRICTS) {
    if (d.contains(location)) return d;
  }
  return null;
}

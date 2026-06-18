// lib/utils/lat_lng_list.dart
//
// Pure (de)serialization for List<LatLng> as a JSON array of
// [lat, lng] pairs. Used to persist the visited-cell locations
// alongside the visited-cell set so the green footprint overlay
// survives an app restart.

import 'dart:convert';

import 'package:latlong2/latlong.dart';

/// Encode a [List]&lt;[LatLng]&gt; as a JSON array of [lat, lng]
/// pairs. Returns `'[]'` for null or empty input.
String latLngListToJson(List<LatLng>? points) {
  if (points == null || points.isEmpty) return '[]';
  return jsonEncode(points.map((p) => [p.latitude, p.longitude]).toList());
}

/// Decode a JSON array string back into a [List]&lt;[LatLng]&gt;.
/// Returns an empty list for null, empty, or malformed input.
///
/// Per-entry decoding failures are isolated: a single bad
/// entry (wrong shape, non-numeric, out-of-range) is skipped
/// without discarding subsequent valid entries. The previous
/// implementation wrapped the whole loop in one try/catch,
/// so a single [22.1, "114.1"] (string lng) would silently
/// nuke every earlier valid point and return [].
List<LatLng> latLngListFromJson(String? json) {
  if (json == null || json.isEmpty) return <LatLng>[];
  final dynamic decoded;
  try {
    decoded = jsonDecode(json);
  } catch (_) {
    return <LatLng>[];
  }
  if (decoded is! List) return <LatLng>[];
  final out = <LatLng>[];
  for (final entry in decoded) {
    if (entry is! List || entry.length < 2) continue;
    final lat = entry[0];
    final lng = entry[1];
    if (lat is! num || lng is! num) continue;
    final latD = lat.toDouble();
    final lngD = lng.toDouble();
    // Sanity-check the ranges so a corrupted prefs file
    // doesn't put a LatLng(999, 999) on the map.
    if (latD < -90 || latD > 90 || lngD < -180 || lngD > 180) continue;
    out.add(LatLng(latD, lngD));
  }
  return out;
}

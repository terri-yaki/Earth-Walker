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
List<LatLng> latLngListFromJson(String? json) {
  if (json == null || json.isEmpty) return <LatLng>[];
  try {
    final decoded = jsonDecode(json);
    if (decoded is! List) return <LatLng>[];
    final out = <LatLng>[];
    for (final entry in decoded) {
      if (entry is List && entry.length >= 2) {
        out.add(LatLng(
          (entry[0] as num).toDouble(),
          (entry[1] as num).toDouble(),
        ));
      }
    }
    return out;
  } catch (_) {
    return <LatLng>[];
  }
}

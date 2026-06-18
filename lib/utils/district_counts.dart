// lib/utils/district_counts.dart
//
// Pure (de)serialization for the per-district visit-count map.
// Kept Flutter-free so the format is unit-testable on plain
// 'flutter test' with no SharedPreferences mock plumbing.

import 'dart:convert';

/// Encode a `Map<String, int>` of district-name -> cell-count as a
/// JSON object string. Returns `'{}'` for null or empty input.
String districtCountMapToJson(Map<String, int>? counts) {
  if (counts == null || counts.isEmpty) return '{}';
  return jsonEncode(counts);
}

/// Decode a JSON object string back into a `Map<String, int>`.
/// Returns an empty map for null, empty, or malformed input.
///
/// Per-entry decoding failures are isolated: a single
/// non-numeric value (e.g. {"Yau Tsim Mong": "12"} with a
/// string value) is skipped without discarding the rest.
/// The previous implementation wrapped the whole map in
/// one try/catch, so one bad value nuked every other
/// district's count.
Map<String, int> districtCountMapFromJson(String? json) {
  if (json == null || json.isEmpty) return <String, int>{};
  final dynamic decoded;
  try {
    decoded = jsonDecode(json);
  } catch (_) {
    return <String, int>{};
  }
  if (decoded is! Map) return <String, int>{};
  final out = <String, int>{};
  decoded.forEach((k, v) {
    if (v is num) {
      out[k.toString()] = v.toInt();
    }
  });
  return out;
}

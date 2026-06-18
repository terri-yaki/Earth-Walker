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
Map<String, int> districtCountMapFromJson(String? json) {
  if (json == null || json.isEmpty) return <String, int>{};
  try {
    final decoded = jsonDecode(json);
    if (decoded is! Map) return <String, int>{};
    return decoded.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
  } catch (_) {
    return <String, int>{};
  }
}

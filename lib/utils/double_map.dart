// lib/utils/double_map.dart
//
// Pure (de)serialization for Map<String, double>. Mirrors the
// pattern used by district_counts.dart and visited_cells_store.dart:
// Flutter-free helpers so the format is unit-testable on plain
// 'flutter test' with no SharedPreferences mock plumbing.

import 'dart:convert';

/// Encode a Map<String, double> as a JSON object string. Returns
/// `'{}'` for null or empty input.
String doubleMapToJson(Map<String, double>? values) {
  if (values == null || values.isEmpty) return '{}';
  return jsonEncode(values);
}

/// Decode a JSON object string back into a Map<String, double>.
/// Returns an empty map for null, empty, or malformed input.
///
/// Per-entry decoding failures are isolated: a single
/// non-numeric value is skipped without discarding the rest.
/// See district_counts.dart for the rationale.
Map<String, double> doubleMapFromJson(String? json) {
  if (json == null || json.isEmpty) return <String, double>{};
  final dynamic decoded;
  try {
    decoded = jsonDecode(json);
  } catch (_) {
    return <String, double>{};
  }
  if (decoded is! Map) return <String, double>{};
  final out = <String, double>{};
  decoded.forEach((k, v) {
    if (v is num) {
      out[k.toString()] = v.toDouble();
    }
  });
  return out;
}

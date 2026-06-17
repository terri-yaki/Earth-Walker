// lib/utils/visited_cells_store.dart
//
// Pure-Dart helpers for serializing the visited-geohash-cells set to and
// from a JSON string. Kept separate from UserLocationProvider and from
// any Flutter plugin so the encoding is unit-testable on a vanilla
// `flutter test` run with no SharedPreferences mock.

import 'dart:convert';

/// Encode a set of geohash cell strings as a JSON array string.
/// Returns `'[]'` for null or empty input.
String cellsToJson(Set<String>? cells) {
  if (cells == null || cells.isEmpty) return '[]';
  return jsonEncode(cells.toList(growable: false));
}

/// Decode a JSON array string back into a set of geohash cell strings.
/// Returns an empty set for null, empty, or malformed input (we'd rather
/// start fresh than crash the app on a corrupt prefs file).
Set<String> cellsFromJson(String? json) {
  if (json == null || json.isEmpty) return <String>{};
  try {
    final decoded = jsonDecode(json);
    if (decoded is! List) return <String>{};
    return decoded.whereType<String>().toSet();
  } catch (_) {
    return <String>{};
  }
}

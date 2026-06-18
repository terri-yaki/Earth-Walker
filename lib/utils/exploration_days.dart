// lib/utils/exploration_days.dart
//
// Pure helpers for tracking the set of unique calendar days the user
// has explored on. A 'day key' is the local-time yyyy-mm-dd for the
// date a new cell was first entered. Kept Flutter-free so the
// formatting is unit-testable.

/// Encode a [DateTime] as a 'yyyy-mm-dd' string in its local time zone.
/// Local time, not UTC, because what matters for the user is "did I
/// go out on Tuesday", not "was the server in the same day as me".
String dayKey(DateTime when) {
  final y = when.year.toString().padLeft(4, '0');
  final m = when.month.toString().padLeft(2, '0');
  final d = when.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Decode a 'yyyy-mm-dd' string back to a [DateTime] (local midnight).
/// Returns null on malformed input ??callers can choose to drop the
/// entry rather than crash.
DateTime? dayKeyParse(String key) {
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(key);
  if (m == null) return null;
  return DateTime(
    int.parse(m.group(1)!),
    int.parse(m.group(2)!),
    int.parse(m.group(3)!),
  );
}

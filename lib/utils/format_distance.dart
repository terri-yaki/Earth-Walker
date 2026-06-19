// lib/utils/format_distance.dart
//
// Pure helper for rendering a distance in meters as a short,
// locale-agnostic string. Used by the map HUD, the progress
// summary line, and the share post —the three places a user
// sees their walked distance in a sentence context.
//
// Branching rules (locked by tests):
//   meters < 1000        -> "X m" (integer meters)
//   meters >= 1000       -> "X.Y km" (one decimal)
// The branch is on the rounded integer-meter value, not the
// raw double, so 999.5 rounds to "1000 m" (correctly) and
// the next reading of 1000.0 produces "1.0 km" without a
// duplicate "1000 m" frame in between.
//
// Inputs are clamped to 0 m so a bad GPS fix (NaN, Infinity,
// negative) renders as "0 m" rather than "NaN km" / "-1 m".
String formatDistance(double meters) {
  // Clamp bad GPS inputs (NaN, Infinity, negative) to 0 m so
  // the user sees "0 m" rather than "NaN km" / "-1 m" /
  // "Infinity km". Using a local `clamped` variable rather
  // than reassigning the `meters` parameter (the linter flags
  // the latter as bad form and the test files would need to
  // ignore the warning).
  final clamped = meters.isNaN || meters.isInfinite || meters < 0
      ? 0.0
      : meters;
  final metersRounded = clamped.toStringAsFixed(0);
  if (double.parse(metersRounded) < 1000) return '$metersRounded m';
  final km = clamped / 1000;
  return '${km.toStringAsFixed(1)} km';
}

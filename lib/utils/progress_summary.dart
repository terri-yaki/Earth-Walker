// lib/utils/progress_summary.dart
//
// Pure helpers for formatting a one-line progress summary used by the
// drawer's Reset Progress confirmation and its Copy-to-clipboard action.

/// Format a one-line progress summary for copy/share. Pure so it's
/// trivially unit-testable.
String formatProgressSummary({
  required int cellsVisited,
  required int badgesUnlocked,
  required int medalsEarned,
  required double metersWalked,
}) {
  final km = (metersWalked / 1000).toStringAsFixed(1);
  return '$cellsVisited cells visited, '
      '$badgesUnlocked badges unlocked, '
      '$medalsEarned medals earned, '
      '$km km walked.';
}

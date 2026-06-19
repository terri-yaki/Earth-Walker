// lib/utils/progress_summary.dart
//
// Pure helpers for formatting a one-line progress summary used by
// the drawer's Reset Progress confirmation + Copy-to-clipboard
// action, and for serialising / parsing the shareable progress
// snapshot that lets one Urbix HK user send their stats to
// another (via copy/share) and the receiver compare against
// their own.

/// Format a one-line progress summary for copy/share. Pure so it's
/// trivially unit-testable.
///
/// [cellsLabel], [badgesLabel], [medalsLabel], and [distanceLabel] are
/// passed in (rather than looked up here) so this function stays pure
/// and the caller owns the localisation. Typical use:
///
///   formatProgressSummary(
///     cellsVisited: ..., badgesUnlocked: ..., medalsEarned: ...,
///     metersWalked: ...,
///     cellsLabel: l.cellPlural, badgesLabel: 'badges',
///     medalsLabel: 'medals', distanceLabel: 'km',
///   );
String formatProgressSummary({
  required int cellsVisited,
  required int badgesUnlocked,
  required int medalsEarned,
  required double metersWalked,
  required String cellsLabel,
  required String badgesLabel,
  required String medalsLabel,
  required String distanceLabel,
}) {
  final km = (metersWalked / 1000).toStringAsFixed(1);
  return '$cellsVisited $cellsLabel visited, '
      '$badgesUnlocked $badgesLabel unlocked, '
      '$medalsEarned $medalsLabel earned, '
      '$km $distanceLabel walked.';
}

/// Magic prefix for a shareable progress snapshot. The receiver
/// detects this on paste, calls [parseProgressSnapshot], and gets
/// a [ProgressSnapshot] back; if the prefix is missing, the
/// pasted text was just a plain string and the caller should
/// surface it as a "couldn't parse" error.
const String kProgressSnapshotPrefix = 'URBIX:SNAP:1:';

/// Immutable record of one user's progress, intended to be
/// shared with another user so they can compare. Fields chosen
/// to be the same numbers the HUD surfaces, so a "you vs your
/// friend" comparison makes sense without any extra mapping.
class ProgressSnapshot {
  final int cellsVisited;
  final int badgesUnlocked;
  final int medalsEarned;
  final double metersWalked;
  final int daysExplored;
  final int currentStreakDays;

  const ProgressSnapshot({
    required this.cellsVisited,
    required this.badgesUnlocked,
    required this.medalsEarned,
    required this.metersWalked,
    required this.daysExplored,
    required this.currentStreakDays,
  });

  /// Build a snapshot from the current provider state. Pure data
  /// class, no Provider dependency.
  factory ProgressSnapshot.fromValues({
    required int cellsVisited,
    required int badgesUnlocked,
    required int medalsEarned,
    required double metersWalked,
    required int daysExplored,
    required int currentStreakDays,
  }) =>
      ProgressSnapshot(
        cellsVisited: cellsVisited,
        badgesUnlocked: badgesUnlocked,
        medalsEarned: medalsEarned,
        metersWalked: metersWalked,
        daysExplored: daysExplored,
        currentStreakDays: currentStreakDays,
      );

  /// Build a snapshot from a JSON map (the persisted form, or the
  /// decoded form of a shareable URL). Missing fields default to 0
  /// so older snapshots from before a field was added still parse.
  factory ProgressSnapshot.fromJson(Map<String, dynamic> json) =>
      ProgressSnapshot(
        cellsVisited: (json['cells'] as num?)?.toInt() ?? 0,
        badgesUnlocked: (json['badges'] as num?)?.toInt() ?? 0,
        medalsEarned: (json['medals'] as num?)?.toInt() ?? 0,
        metersWalked: (json['meters'] as num?)?.toDouble() ?? 0.0,
        daysExplored: (json['days'] as num?)?.toInt() ?? 0,
        currentStreakDays: (json['streak'] as num?)?.toInt() ?? 0,
      );

  /// Encode as a JSON map for persistence or URL encoding.
  Map<String, dynamic> toJson() => {
        'cells': cellsVisited,
        'badges': badgesUnlocked,
        'medals': medalsEarned,
        'meters': metersWalked,
        'days': daysExplored,
        'streak': currentStreakDays,
      };

  /// Compare two snapshots field-by-field. Returns a list of
  /// human-readable lines like 'they walked 3.2 km more than
  /// you'. A field is omitted when the two values are equal (so
  /// the user only sees the deltas that matter).
  ///
  /// Direction: [other] is the friend's snapshot just imported,
  /// [yours] is the local user. A positive delta means they
  /// have more; negative means you have more. The display labels
  /// are passed in so the strings can be localized.
  static List<String> compare({
    required ProgressSnapshot other,
    required ProgressSnapshot yours,
    required String cellsLabel,
    required String distanceLabel,
    required String badgesLabel,
    required String medalsLabel,
    required String daysLabel,
    required String streakLabel,
    required String youWinLabel,
    required String theyWinLabel,
  }) {
    String line(int delta, String label, {bool isMeters = false}) {
      final value = isMeters
          ? '${(delta.abs() / 1000).toStringAsFixed(1)} km $distanceLabel'
          : '${delta.abs()} $label';
      return '$value (${delta > 0 ? theyWinLabel : youWinLabel})';
    }

    final lines = <String>[];
    final dCells = other.cellsVisited - yours.cellsVisited;
    if (dCells != 0) lines.add(line(dCells, cellsLabel));
    final dMeters = other.metersWalked - yours.metersWalked;
    if (dMeters.abs() > 50) {
      // > 50 m counts as a real difference; smaller is GPS noise.
      lines.add(line(dMeters.toInt(), distanceLabel, isMeters: true));
    }
    final dBadges = other.badgesUnlocked - yours.badgesUnlocked;
    if (dBadges != 0) lines.add(line(dBadges, badgesLabel));
    final dMedals = other.medalsEarned - yours.medalsEarned;
    if (dMedals != 0) lines.add(line(dMedals, medalsLabel));
    final dDays = other.daysExplored - yours.daysExplored;
    if (dDays != 0) lines.add(line(dDays, daysLabel));
    final dStreak = other.currentStreakDays - yours.currentStreakDays;
    if (dStreak != 0) lines.add(line(dStreak, streakLabel));
    return lines;
  }
}

/// Serialise a [ProgressSnapshot] to the shareable string form.
/// Always includes the [kProgressSnapshotPrefix] so the receiver
/// can detect it as a snapshot, not just a free-form sentence.
///
/// The body uses comma-separated key=value pairs instead of full
/// JSON. This keeps the shareable string short, human-readable
/// (a curious user can read the fields by hand), and
/// unambiguously parseable without ambiguity about quote
/// escaping in chat apps.
String encodeProgressSnapshot(ProgressSnapshot s) {
  final body = [
    'cells=${s.cellsVisited}',
    'badges=${s.badgesUnlocked}',
    'medals=${s.medalsEarned}',
    'meters=${s.metersWalked.toStringAsFixed(0)}',
    'days=${s.daysExplored}',
    'streak=${s.currentStreakDays}',
  ].join(',');
  return '$kProgressSnapshotPrefix$body';
}

/// Parse a [ProgressSnapshot] from a shareable string. Returns
/// null if [text] doesn't start with [kProgressSnapshotPrefix] or
/// any field is missing / unparseable. The caller should
/// surface "couldn't parse" to the user when null is returned.
///
/// Duplicate keys are rejected: a snapshot like
/// 'URBIX:SNAP:1:cells=1,...,cells=99,...' is treated as
/// malformed (the spec is one value per field). Without this
/// check, a corrupted or malicious paste could silently
/// override a field with the second occurrence.
///
/// Negative values are rejected (clamped to 0 instead): the
/// domain is "things you've accumulated", which can't be
/// negative. A snapshot like '...cells=-5,...' would
/// otherwise produce a ProgressSnapshot with cellsVisited: -5
/// and render as "you walked -5 cells" in the compare dialog.
ProgressSnapshot? parseProgressSnapshot(String text) {
  if (!text.startsWith(kProgressSnapshotPrefix)) return null;
  final body = text.substring(kProgressSnapshotPrefix.length);
  final fields = <String, String>{};
  for (final part in body.split(',')) {
    final eq = part.indexOf('=');
    if (eq <= 0) continue;
    final key = part.substring(0, eq);
    // Reject duplicates — see the docstring for why.
    if (fields.containsKey(key)) return null;
    fields[key] = part.substring(eq + 1);
  }
  num? n(String k) => num.tryParse(fields[k] ?? '');
  final cells = n('cells')?.toInt();
  final badges = n('badges')?.toInt();
  final medals = n('medals')?.toInt();
  final meters = n('meters')?.toDouble();
  final days = n('days')?.toInt();
  final streak = n('streak')?.toInt();
  if (cells == null ||
      badges == null ||
      medals == null ||
      meters == null ||
      days == null ||
      streak == null) {
    return null;
  }
  // Reject any negative value — the domain (cells / badges /
  // medals / meters / days / streak) is non-negative. Allowing
  // negatives would let a malformed paste produce display
  // text like "you walked -5 cells". Treat as parse failure
  // so the caller surfaces "couldn't parse" instead.
  if (cells < 0 ||
      badges < 0 ||
      medals < 0 ||
      meters < 0 ||
      days < 0 ||
      streak < 0) {
    return null;
  }
  return ProgressSnapshot(
    cellsVisited: cells,
    badgesUnlocked: badges,
    medalsEarned: medals,
    metersWalked: meters,
    daysExplored: days,
    currentStreakDays: streak,
  );
}

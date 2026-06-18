// lib/utils/share_text.dart
//
// Pure helpers for building the message body that the share
// dialog hands to the OS share sheet (iOS UIActivityViewController
// / Android Intent.ACTION_SEND). The message is a real post,
// not a data dump: one brag line, a hashtag, then the snapshot
// string at the bottom so the receiver can still compare.

import 'progress_summary.dart' show ProgressSnapshot, encodeProgressSnapshot;

/// Hashtag appended to every share post. Discoverability is the
/// whole point of using social media, so this is non-negotiable.
const String kShareHashtag = '#UrbixHK';

/// Build the body of a share post from the user's current
/// [ProgressSnapshot] and the localised brag line. The snapshot
/// is appended at the end so a friend can paste the whole thing
/// into the Compare dialog and the parser will still see the
/// `URBIX:SNAP:1:` prefix.
///
/// [bragLine] is whatever the share dialog chose —the default
/// "I've walked X km" line, a streak brag, or a badge brag.
/// Templates are passed in (rather than looked up here) so this
/// function stays pure and testable; the caller owns L10n.
String formatShareText({
  required ProgressSnapshot snapshot,
  required String bragLine,
}) {
  final km = (snapshot.metersWalked / 1000).toStringAsFixed(1);
  final cells = snapshot.cellsVisited;
  final streak = snapshot.currentStreakDays;
  // 3 short lines, then snapshot. ~200 chars before the snapshot,
  // well inside the 280-char X / Threads cap on the readable
  // portion. The snapshot line is unbounded but most chat apps
  // (WhatsApp, Telegram, IG DM, FB Messenger) treat it as a
  // monospace blob and don't break on it.
  final buf = StringBuffer()
    ..writeln(bragLine)
    ..writeln(
        '$km km ??$cells cells ??$streak ${streak == 1 ? "day" : "days"} streak')
    ..writeln(kShareHashtag)
    ..write(encodeProgressSnapshot(snapshot));
  return buf.toString();
}

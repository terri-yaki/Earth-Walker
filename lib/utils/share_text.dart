// lib/utils/share_text.dart
//
// Pure helpers for building the message body that the share
// dialog hands to the OS share sheet (iOS UIActivityViewController
// / Android Intent.ACTION_SEND). The message is a real post,
// not a data dump: one brag line, a hashtag, then the snapshot
// string at the bottom so the receiver can still compare.

import 'format_distance.dart';
import 'progress_summary.dart'
    show ProgressSnapshot, encodeProgressSnapshot, pluralize;

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
  // Use [formatDistance] so sub-kilometre walkers render as
  // "50 m" rather than "0.1 km" / "0.0 km" — the latter
  // round to zero and read like the user hasn't moved.
  final dist = formatDistance(snapshot.metersWalked);
  final cells = snapshot.cellsVisited;
  final streak = snapshot.currentStreakDays;
  // 3 short lines, then snapshot. ~200 chars before the snapshot,
  // well inside the 280-char X / Threads cap on the readable
  // portion. The snapshot line is unbounded but most chat apps
  // (WhatsApp, Telegram, IG DM, FB Messenger) treat it as a
  // monospace blob and don't break on it.
  //
  // Pluralization goes through [pluralize] for consistency with
  // the compare-dialog labels. Note the difference from the
  // compare dialog: there the label is the compound noun
  // "day streak" (singular form works for both 1 and N), here
  // we split it into the count noun ("day" / "days") + " streak"
  // because the share post is a free-form sentence and reads
  // better that way ("1 day streak", "5 days streak").
  final buf = StringBuffer()
    ..writeln(bragLine)
    ..writeln(
        '$dist · $cells ${pluralize(cells, "cell", "cells")} · $streak ${pluralize(streak, "day", "days")} streak')
    ..writeln(kShareHashtag)
    ..write(encodeProgressSnapshot(snapshot));
  return buf.toString();
}

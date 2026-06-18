import 'package:flutter_test/flutter_test.dart';
import 'package:urbix/utils/progress_summary.dart';
import 'package:urbix/utils/share_text.dart';

void main() {
  group('formatShareText', () {
    test('contains the brag line, the hashtag, and the snapshot', () {
      const snap = ProgressSnapshot(
        cellsVisited: 12,
        badgesUnlocked: 3,
        medalsEarned: 2,
        metersWalked: 4321.0,
        daysExplored: 5,
        currentStreakDays: 2,
      );
      final out = formatShareText(
        snapshot: snap,
        bragLine: 'On a roll.',
      );
      expect(out, contains('On a roll.'));
      expect(out, contains('#UrbixHK'));
      expect(out, contains('URBIX:SNAP:1:'));
      expect(out, contains('cells=12'));
    });

    test('singular day vs plural days in the stat line', () {
      const one = ProgressSnapshot(
        cellsVisited: 0,
        badgesUnlocked: 0,
        medalsEarned: 0,
        metersWalked: 1000.0,
        daysExplored: 1,
        currentStreakDays: 1,
      );
      const many = ProgressSnapshot(
        cellsVisited: 0,
        badgesUnlocked: 0,
        medalsEarned: 0,
        metersWalked: 1000.0,
        daysExplored: 1,
        currentStreakDays: 7,
      );
      final outOne = formatShareText(snapshot: one, bragLine: 'x');
      final outMany = formatShareText(snapshot: many, bragLine: 'x');
      // '1 day' (singular) vs '7 days' (plural).
      expect(outOne, contains('1 day streak'));
      expect(outMany, contains('7 days streak'));
    });

    test('km is rendered with one decimal place', () {
      const snap = ProgressSnapshot(
        cellsVisited: 1,
        badgesUnlocked: 0,
        medalsEarned: 0,
        metersWalked: 12345.0,
        daysExplored: 1,
        currentStreakDays: 1,
      );
      final out = formatShareText(snapshot: snap, bragLine: 'x');
      expect(out, contains('12.3 km'));
    });

    test('ends with the snapshot (no trailing newline)', () {
      const snap = ProgressSnapshot(
        cellsVisited: 0,
        badgesUnlocked: 0,
        medalsEarned: 0,
        metersWalked: 0.0,
        daysExplored: 0,
        currentStreakDays: 0,
      );
      final out = formatShareText(snapshot: snap, bragLine: 'hi');
      expect(out.endsWith('\n'), isFalse);
      expect(out, endsWith(encodeProgressSnapshot(snap)));
    });
  });
}

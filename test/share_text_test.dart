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

    test(
        'zero-day streak renders with "days" (plural for zero, '
        'consistent with English grammar)', () {
      // 0 is grammatically plural ("zero days", not "zero day"),
      // so the streak == 1 special case correctly excludes 0.
      const zero = ProgressSnapshot(
        cellsVisited: 5,
        badgesUnlocked: 0,
        medalsEarned: 0,
        metersWalked: 1000.0,
        daysExplored: 1,
        currentStreakDays: 0,
      );
      final out = formatShareText(snapshot: zero, bragLine: 'x');
      expect(out, contains('0 days streak'));
      expect(out, isNot(contains('0 day streak')));
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

    test('sub-kilometre distances render as meters, not 0.0 km', () {
      // 49 m would round to "0.0 km" under the old flat-km
      // conversion — visually misleading for the user who has
      // walked 49 m. formatDistance picks meters for
      // sub-1000 m values.
      const snap = ProgressSnapshot(
        cellsVisited: 0,
        badgesUnlocked: 0,
        medalsEarned: 0,
        metersWalked: 49,
        daysExplored: 0,
        currentStreakDays: 0,
      );
      final out = formatShareText(snapshot: snap, bragLine: 'x');
      expect(out, contains('49 m'));
      expect(out, isNot(contains('0.0 km')));
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

    test('singular "cell" / plural "cells" matches the count', () {
      // Regression: the format used to hardcode "cells" even
      // for cellsVisited=1, producing "1 cells". Now the noun
      // agrees with the number.
      const one = ProgressSnapshot(
        cellsVisited: 1,
        badgesUnlocked: 0,
        medalsEarned: 0,
        metersWalked: 1000.0,
        daysExplored: 1,
        currentStreakDays: 0,
      );
      final outOne = formatShareText(snapshot: one, bragLine: 'x');
      expect(outOne, contains('1 cell '),
          reason: 'cellsVisited=1 should render as "1 cell "');
      expect(outOne, isNot(contains('1 cells')),
          reason: 'must not say "1 cells"');
      // 0 is grammatically plural ("zero cells", not "zero
      // cell"), and 2+ is naturally plural.
      const zero = ProgressSnapshot(
        cellsVisited: 0,
        badgesUnlocked: 0,
        medalsEarned: 0,
        metersWalked: 1000.0,
        daysExplored: 1,
        currentStreakDays: 0,
      );
      final outZero = formatShareText(snapshot: zero, bragLine: 'x');
      expect(outZero, contains('0 cells'));
      const many = ProgressSnapshot(
        cellsVisited: 12,
        badgesUnlocked: 0,
        medalsEarned: 0,
        metersWalked: 1000.0,
        daysExplored: 1,
        currentStreakDays: 0,
      );
      final outMany = formatShareText(snapshot: many, bragLine: 'x');
      expect(outMany, contains('12 cells'));
    });
  });
}

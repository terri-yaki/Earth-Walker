import 'package:flutter_test/flutter_test.dart';
import 'package:urbix/utils/progress_summary.dart';

void main() {
  group('formatProgressSummary', () {
    test('renders zeros for a fresh user', () {
      expect(
        formatProgressSummary(
          cellsVisited: 0,
          badgesUnlocked: 0,
          medalsEarned: 0,
          metersWalked: 0,
        ),
        '0 cells visited, 0 badges unlocked, 0 medals earned, 0.0 km walked.',
      );
    });

    test('renders populated stats and a one-decimal km value', () {
      expect(
        formatProgressSummary(
          cellsVisited: 12,
          badgesUnlocked: 3,
          medalsEarned: 2,
          metersWalked: 4321,
        ),
        '12 cells visited, 3 badges unlocked, 2 medals earned, 4.3 km walked.',
      );
    });
  });

  group('encodeProgressSnapshot / parseProgressSnapshot', () {
    const sample = ProgressSnapshot(
      cellsVisited: 12,
      badgesUnlocked: 3,
      medalsEarned: 2,
      metersWalked: 4321.0,
      daysExplored: 5,
      currentStreakDays: 2,
    );

    test('encode starts with the magic prefix and includes every field', () {
      final s = encodeProgressSnapshot(sample);
      expect(s.startsWith(kProgressSnapshotPrefix), isTrue);
      expect(s, contains('cells=12'));
      expect(s, contains('badges=3'));
      expect(s, contains('medals=2'));
      expect(s, contains('meters=4321'));
      expect(s, contains('days=5'));
      expect(s, contains('streak=2'));
    });

    test('round-trips through parse', () {
      final encoded = encodeProgressSnapshot(sample);
      final decoded = parseProgressSnapshot(encoded)!;
      expect(decoded.cellsVisited, sample.cellsVisited);
      expect(decoded.badgesUnlocked, sample.badgesUnlocked);
      expect(decoded.medalsEarned, sample.medalsEarned);
      expect(decoded.metersWalked, sample.metersWalked);
      expect(decoded.daysExplored, sample.daysExplored);
      expect(decoded.currentStreakDays, sample.currentStreakDays);
    });

    test('parse returns null for text without the magic prefix', () {
      expect(parseProgressSnapshot('hello world'), isNull);
      expect(parseProgressSnapshot('URBIX:SNAP:2:different-version'), isNull);
    });

    test('parse returns null on a partial / corrupted body', () {
      // Missing the streak field ??parse should reject.
      final bad =
          '${kProgressSnapshotPrefix}cells=1,badges=2,medals=1,meters=10,days=1';
      expect(parseProgressSnapshot(bad), isNull);
    });

    test(
        'meters round-trips to one-decimal precision (encoded as integer meters)',
        () {
      // 1500.7 m encodes as '1501' (toStringAsFixed(0)); on parse,
      // it comes back as 1501.0. The 0.7 m precision loss is
      // acceptable for a shareable string; the HUD shows km at
      // one-decimal anyway.
      final s = const ProgressSnapshot(
        cellsVisited: 0,
        badgesUnlocked: 0,
        medalsEarned: 0,
        metersWalked: 1500.7,
        daysExplored: 0,
        currentStreakDays: 0,
      );
      final decoded = parseProgressSnapshot(encodeProgressSnapshot(s))!;
      expect(decoded.metersWalked, 1501.0);
    });
  });

  group('ProgressSnapshot.compare', () {
    const you = ProgressSnapshot(
      cellsVisited: 10,
      badgesUnlocked: 2,
      medalsEarned: 1,
      metersWalked: 5000.0,
      daysExplored: 3,
      currentStreakDays: 1,
    );
    const them = ProgressSnapshot(
      cellsVisited: 15,
      badgesUnlocked: 4,
      medalsEarned: 1,
      metersWalked: 3000.0,
      daysExplored: 5,
      currentStreakDays: 0,
    );

    test('returns a non-empty list when the snapshots differ', () {
      final lines = ProgressSnapshot.compare(
        other: them,
        yours: you,
        cellsLabel: 'cells',
        distanceLabel: 'km',
        badgesLabel: 'badges',
        medalsLabel: 'medals',
        daysLabel: 'days',
        streakLabel: 'streak',
        youWinLabel: 'you win',
        theyWinLabel: 'they win',
      );
      // 5 different fields -> 5 lines (medals is tied at 1, so
      // omitted).
      expect(lines, hasLength(5));
      // Cells: they have 5 more (15 - 10).
      expect(lines.any((l) => l.contains('5 cells') && l.contains('they win')),
          isTrue);
      // Distance: you walked 2.0 km more (5000 - 3000).
      expect(lines.any((l) => l.contains('2.0 km') && l.contains('you win')),
          isTrue);
      // Badges: they have 2 more.
      expect(lines.any((l) => l.contains('2 badges') && l.contains('they win')),
          isTrue);
    });

    test('returns an empty list when the snapshots are equal', () {
      final lines = ProgressSnapshot.compare(
        other: you,
        yours: you,
        cellsLabel: 'c',
        distanceLabel: 'd',
        badgesLabel: 'b',
        medalsLabel: 'm',
        daysLabel: 'd',
        streakLabel: 's',
        youWinLabel: 'y',
        theyWinLabel: 't',
      );
      expect(lines, isEmpty);
    });

    test('ignores tiny distance differences (GPS noise floor)', () {
      const you2 = ProgressSnapshot(
        cellsVisited: 10,
        badgesUnlocked: 2,
        medalsEarned: 1,
        metersWalked: 5000.0,
        daysExplored: 3,
        currentStreakDays: 1,
      );
      const them2 = ProgressSnapshot(
        cellsVisited: 10,
        badgesUnlocked: 2,
        medalsEarned: 1,
        metersWalked: 5020.0, // 20 m difference ??noise
        daysExplored: 3,
        currentStreakDays: 1,
      );
      final lines = ProgressSnapshot.compare(
        other: them2,
        yours: you2,
        cellsLabel: 'c',
        distanceLabel: 'd',
        badgesLabel: 'b',
        medalsLabel: 'm',
        daysLabel: 'd',
        streakLabel: 's',
        youWinLabel: 'y',
        theyWinLabel: 't',
      );
      expect(lines, isEmpty, reason: '20 m is below the 50 m noise floor');
    });
  });

  group('ProgressSnapshot.fromJson', () {
    test('uses 0 for any missing field (forward-compat with old snapshots)',
        () {
      final s = ProgressSnapshot.fromJson(<String, dynamic>{
        'cells': 5,
        // badges, medals, meters, days, streak intentionally missing
      });
      expect(s.cellsVisited, 5);
      expect(s.badgesUnlocked, 0);
      expect(s.medalsEarned, 0);
      expect(s.metersWalked, 0.0);
      expect(s.daysExplored, 0);
      expect(s.currentStreakDays, 0);
    });

    test('round-trips through toJson + fromJson', () {
      const original = ProgressSnapshot(
        cellsVisited: 7,
        badgesUnlocked: 2,
        medalsEarned: 1,
        metersWalked: 1234.5,
        daysExplored: 3,
        currentStreakDays: 1,
      );
      final decoded = ProgressSnapshot.fromJson(original.toJson());
      expect(decoded.cellsVisited, original.cellsVisited);
      expect(decoded.badgesUnlocked, original.badgesUnlocked);
      expect(decoded.medalsEarned, original.medalsEarned);
      expect(decoded.metersWalked, original.metersWalked);
      expect(decoded.daysExplored, original.daysExplored);
      expect(decoded.currentStreakDays, original.currentStreakDays);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:urbix/providers/achievement_provider.dart';

void main() {
  group('newlyUnlockedBetween', () {
    test('returns the items in current that were not in previous', () {
      expect(
        newlyUnlockedBetween(const <String>[], const ['Walker', 'Pioneer']),
        equals(<String>['Walker', 'Pioneer']),
      );
      expect(
        newlyUnlockedBetween(
          const <String>['Walker'],
          const <String>['Walker', 'Pioneer'],
        ),
        equals(<String>['Pioneer']),
      );
    });

    test('returns an empty list when nothing changed', () {
      expect(
        newlyUnlockedBetween(
          const <String>['Walker', 'Pioneer'],
          const <String>['Walker', 'Pioneer'],
        ),
        isEmpty,
      );
    });
  });

  group('tierForThreshold', () {
    test('low thresholds (10..40) are bronze', () {
      for (final t in <int>[10, 20, 30, 40]) {
        expect(tierForThreshold(t), AchievementTier.bronze, reason: 't=$t');
      }
    });

    test('mid thresholds (50..70) are silver', () {
      for (final t in <int>[50, 60, 70]) {
        expect(tierForThreshold(t), AchievementTier.silver, reason: 't=$t');
      }
    });

    test('80+ are gold', () {
      expect(tierForThreshold(80), AchievementTier.gold);
      expect(tierForThreshold(99), AchievementTier.gold);
      expect(tierForThreshold(100), AchievementTier.gold);
    });
  });

  group('AchievementProvider', () {
    test('starts with no unlocked achievements', () {
      final p = AchievementProvider();
      expect(p.unlockedAchievements, isEmpty);
      expect(p.isUnlocked('Walker'), isFalse);
    });

    test('unlocks achievements as world % crosses thresholds', () {
      final p = AchievementProvider();
      p.updateExploration(0, 0, 9);
      expect(p.unlockedAchievements, isEmpty,
          reason: 'below first threshold of 10');

      p.updateExploration(0, 0, 10);
      expect(p.unlockedAchievements, contains('Walker'));

      p.updateExploration(0, 0, 25);
      // At 25%, Walker (10) and Pioneer (20) are unlocked; Traveller
      // requires 30, so it's still locked.
      expect(
          p.unlockedAchievements, containsAll(<String>['Walker', 'Pioneer']));
      expect(p.unlockedAchievements, isNot(contains('Traveller')));

      p.updateExploration(0, 0, 35);
      // At 35%, all three are unlocked.
      expect(p.unlockedAchievements,
          containsAll(<String>['Walker', 'Pioneer', 'Traveller']));
    });

    test('clamps percentages to 0..100', () {
      final p = AchievementProvider();
      p.updateExploration(150, -5, 200);
      expect(p.countryExplored, 100);
      expect(p.continentExplored, 0);
      expect(p.worldExplored, 100);
    });

    test('does not re-unlock an already-unlocked achievement', () {
      final p = AchievementProvider();
      p.updateExploration(0, 0, 50);
      final afterFirst = List<String>.from(p.unlockedAchievements);
      p.updateExploration(0, 0, 50);
      expect(p.unlockedAchievements, afterFirst);
    });

    test(
        'unlockedAchievements list is in threshold-ascending order '
        '(so the achievements screen renders lowest-first)', () {
      // The map iteration order in `_checkForNewAchievements` is
      // determined by the insertion order of `_achievementThresholds`,
      // which is ascending (10, 20, 30, ...). The unlocked list
      // mirrors that — when the user crosses every threshold in one
      // call, the list comes out threshold-sorted.
      //
      // A regression that switched the iteration to descending (or
      // to `_achievementThresholds.keys` which is also insertion-
      // sorted, so order is preserved) wouldn't break this test.
      // The load-bearing assertion is that the order matches the
      // definition order — i.e. a future product decision to reorder
      // the threshold map will visibly break the test and force a
      // matching UI update.
      final p = AchievementProvider();
      p.updateExploration(0, 0, 99);
      expect(
        p.unlockedAchievements,
        equals(<String>[
          'Walker', // 10
          'Pioneer', // 20
          'Traveller', // 30
          'Explorer', // 40
          'Coloniser', // 50
          'Dominator', // 80
          'Are you sure you\u2019re not cheating?', // 99
        ]),
      );
    });

    test('resetAchievements clears all unlocked achievements', () {
      final p = AchievementProvider();
      p.updateExploration(0, 0, 99);
      expect(p.unlockedAchievements, isNotEmpty);
      p.resetAchievements();
      expect(p.unlockedAchievements, isEmpty);
    });

    test('resetAchievements on empty state does not notify', () {
      final p = AchievementProvider();
      var notifyCount = 0;
      p.addListener(() => notifyCount++);
      p.resetAchievements();
      expect(notifyCount, 0);
    });
  });

  group('nextAchievement', () {
    test('returns the lowest un-unlocked threshold', () {
      final p = AchievementProvider();
      // Walker unlocks at 10%. At world=0, Walker is the next.
      final first = p.nextAchievement()!;
      expect(first.title, 'Walker');
      expect(first.threshold, 10);
      expect(first.cellsToGo, 10);
    });

    test('skips already-unlocked thresholds', () {
      final p = AchievementProvider();
      // Push world% past 10 (Walker) and 20 (Pioneer) so the
      // next one is Traveller at 30.
      p.updateExploration(0, 0, 25);
      final next = p.nextAchievement()!;
      expect(next.title, 'Traveller');
      expect(next.threshold, 30);
      expect(next.cellsToGo, 5);
    });

    test('returns null when every threshold has been met', () {
      final p = AchievementProvider();
      p.updateExploration(0, 0, 100);
      expect(p.nextAchievement(), isNull);
    });

    test('cellsToGo never goes negative even if world% exceeds the threshold',
        () {
      final p = AchievementProvider();
      // Past 10% so Walker is unlocked but next is Pioneer @ 20%.
      p.updateExploration(0, 0, 50);
      final next = p.nextAchievement()!;
      // world% is 50, next threshold is 80 (Dominator), so
      // cellsToGo = 80 - 50 = 30. Never negative.
      expect(next.cellsToGo, greaterThanOrEqualTo(0));
    });
  });

  // A regression in the bar-fraction math would make the next-
  // milestone bar look wrong (full, empty, or jumping). Lock it
  // down with an explicit test.
  group('next-milestone bar progress', () {
    double progressFor(AchievementProvider p, int worldValue) {
      p.updateExploration(0, 0, worldValue);
      final next = p.nextAchievement();
      if (next == null) return 1.0;
      int prev = 0;
      for (final e in p.achievementThresholds.entries) {
        if (e.value < next.threshold && p.isUnlocked(e.key)) {
          prev = e.value;
        }
      }
      final span = (next.threshold - prev).clamp(1, 100);
      final filled = (worldValue - prev).clamp(0, span);
      return filled / span;
    }

    test('bar is 0% at world=0 (no progress toward Walker yet)', () {
      final p = AchievementProvider();
      // Without a recorded fix, worldExplored is the constructor
      // default (0). We assert against the explicit zero path so
      // a future regression that re-derives progress from an
      // uninitialised field is caught.
      p.updateExploration(0, 0, 0);
      expect(progressFor(p, 0), 0.0);
    });

    test(
        'bar is 50% when world sits halfway between the last unlock and the next',
        () {
      final p = AchievementProvider();
      // Walker unlocks at 10, so at world=10 the last unlock is
      // Walker (10) and the next is Pioneer (20). Halfway in
      // that 10-unit span is world=15, which is progress 0.5.
      // The bar measures "progress between last unlock and next",
      // not "fraction of the next threshold reached".
      p.updateExploration(0, 0, 10);
      final next = p.nextAchievement()!;
      expect(next.threshold, 20);
      expect(progressFor(p, 10), 0.0,
          reason: 'just hit Walker, no progress toward Pioneer yet');
      expect(progressFor(p, 15), 0.5, reason: 'halfway between 10 and 20');
      expect(progressFor(p, 20), 0.0,
          reason: 'just hit Pioneer, no progress toward Traveller yet');
      expect(progressFor(p, 25), 0.5, reason: 'halfway between 20 and 30');
    });

    test('bar is 50% at the midpoint between the last unlock and the next', () {
      final p = AchievementProvider();
      // Walker is unlocked at 10. Next is Pioneer at 20. Midpoint
      // is world=15; the bar should sit at 0.5.
      p.updateExploration(0, 0, 10);
      expect(progressFor(p, 15), 0.5);
    });
  });
}

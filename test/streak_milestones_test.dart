import 'package:flutter_test/flutter_test.dart';
import 'package:urbix/utils/streak_milestones.dart';

void main() {
  group('newStreakShareMilestone', () {
    test('returns null for a fresh user with no streak', () {
      expect(
        newStreakShareMilestone(
          currentStreak: 0,
          alreadyPrompted: <int>{},
        ),
        isNull,
      );
    });

    test('returns null below the first threshold', () {
      expect(
        newStreakShareMilestone(
          currentStreak: 2,
          alreadyPrompted: <int>{},
        ),
        isNull,
      );
    });

    test('returns 3 at the first threshold', () {
      expect(
        newStreakShareMilestone(
          currentStreak: 3,
          alreadyPrompted: <int>{},
        ),
        3,
      );
    });

    test('returns the highest threshold when multiple are crossed at once', () {
      // User went from 0 -> 7 in one update. We want to prompt
      // for 7 (the brag-worthy one), not 3.
      expect(
        newStreakShareMilestone(
          currentStreak: 7,
          alreadyPrompted: <int>{},
        ),
        7,
      );
    });

    test('skips thresholds the caller already prompted for', () {
      // User crossed 3 last week, now crossed 7. We should
      // prompt for 7, not 3.
      expect(
        newStreakShareMilestone(
          currentStreak: 7,
          alreadyPrompted: <int>{3},
        ),
        7,
      );
    });

    test('returns null when every crossed threshold is already prompted', () {
      expect(
        newStreakShareMilestone(
          currentStreak: 14,
          alreadyPrompted: <int>{3, 7, 14},
        ),
        isNull,
      );
    });

    test('does not prompt for a threshold the streak has not reached', () {
      // streak 7 but we ask about 14: should not match.
      expect(
        newStreakShareMilestone(
          currentStreak: 7,
          alreadyPrompted: <int>{},
        ),
        7,
      );
    });

    test('works at the top of the ladder (30-day streak)', () {
      expect(
        newStreakShareMilestone(
          currentStreak: 30,
          alreadyPrompted: <int>{},
        ),
        30,
      );
    });

    test('returns null for a negative streak (defensive)', () {
      // Defensive: a regression that returned `currentStreak` as
      // the prompt-threshold would let negative streaks match
      // the >= 3 comparison. Locks the null return.
      expect(
        newStreakShareMilestone(
          currentStreak: -5,
          alreadyPrompted: <int>{},
        ),
        isNull,
      );
    });

    test('ignores non-threshold entries in alreadyPrompted', () {
      // The alreadyPrompted set might contain other integers from
      // elsewhere (e.g. a UI state machine). The function must
      // look up thresholds by VALUE, not iterate blindly. With
      // garbage values 1, 2, 5 in the set and currentStreak = 7,
      // the function should still find threshold 7.
      expect(
        newStreakShareMilestone(
          currentStreak: 7,
          alreadyPrompted: <int>{1, 2, 5},
        ),
        7,
      );
    });
  });

  group('HUD thresholds', () {
    test('kMinStreakChipDays is 2 (hides single-day streak as noise)',
        () {
      expect(kMinStreakChipDays, 2,
          reason:
              'regression guard: a single-day streak reads as '
              '"today", which the HUD already carries implicitly '
              'via the percentage / days-explored rows. '
              'Surfacing it as a chip would be visual noise.');
    });

    test('kMinStreakShareIconDays equals the first share milestone', () {
      // Locks the coupling between the share-icon threshold and
      // the first kStreakShareMilestones entry. Changing the
      // milestone list without re-checking this test would
      // silently leave the icon visible at the wrong streak
      // length.
      expect(kMinStreakShareIconDays, kStreakShareMilestones[0],
          reason:
              'share-icon threshold must equal the first share '
              'milestone, otherwise the icon would be visible '
              "at a streak length that doesn't trigger a "
              '"Share your streak?" prompt (or vice versa).');
    });
  });
}

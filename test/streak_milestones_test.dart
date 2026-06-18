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
  });
}

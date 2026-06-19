// lib/utils/streak_milestones.dart
//
// Pure helper: decide whether the user has just crossed a
// streak threshold worth prompting "Share your streak?" for.
// Thresholds chosen at the classic habit-app moments (3, 7, 14,
// 30 days) where the user has a real story to tell.

/// Streak thresholds (in days) at which the app should prompt the
/// user to share. Picked at points where a streak starts to feel
/// "real" (3 days = past the initial novelty) and "impressive"
/// (30 days = past casual). ponytail: this is a judgement call;
/// numbers are placeholders. A future product decision might
/// add 60 / 100.
const List<int> kStreakShareMilestones = <int>[3, 7, 14, 30];

/// Lowest streak (in days) at which the HUD's "Streak: N day streak"
/// chip is rendered. A single-day streak reads as just "today",
/// which the HUD already carries implicitly via the percentage /
/// days-explored rows; surfacing it as a chip would be visual noise
/// with no new information.
const int kMinStreakChipDays = 2;

/// Lowest streak (in days) at which the chip's share icon is
/// shown. Coincides with the first share milestone
/// ([kStreakShareMilestones][0]); a sub-3-day streak isn't worth
/// a "Share your streak?" prompt, so there's no point in making
/// the icon visible either.
const int kMinStreakShareIconDays = 3;

/// Returns the highest [kStreakShareMilestones] threshold the
/// user has just crossed —i.e. `currentStreak >= t` and the
/// caller hasn't already prompted for `t`. Returns null if no
/// new milestone was crossed.
///
/// When a user crosses multiple thresholds in one update
/// (e.g. their first session jumps streak from 0 to 7), we
/// return the highest one because the lower one is implicitly
/// subsumed —a "7 day streak" brag is more exciting than
/// "3 day streak" when both are new.
int? newStreakShareMilestone({
  required int currentStreak,
  required Set<int> alreadyPrompted,
}) {
  int? highest;
  for (final t in kStreakShareMilestones) {
    if (currentStreak >= t && !alreadyPrompted.contains(t)) {
      highest = t;
    }
  }
  return highest;
}

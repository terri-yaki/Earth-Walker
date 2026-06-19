// test/medal_screen_test.dart
//
// Widget tests for MedalScreen and AchievementScreen subtitle
// text. Both screens render a per-threshold ListTile whose
// subtitle is "$label $threshold% world exploration". For the
// medal screen, EVERY medal is rendered (locked and awarded) so
// the past-tense "Awarded at" / "Unlocked at" English label
// leaks a misleading "already in hand" implication into
// not-yet-awarded rows that show a lock_outline icon.
//
// The Chinese translations are intentionally threshold-flavored
// (頒發門檻 / 解鎖門檻, "award threshold" / "unlock threshold");
// the English label should match. The fix is to use the
// third-person verb "Awards at" / "Unlocks at" so the line reads
// naturally for both states ("you'll unlock at N%" /
// "this is the threshold").

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:urbix/providers/achievement_provider.dart';
import 'package:urbix/providers/medal_provider.dart';
import 'package:urbix/screens/achievement_screen.dart';
import 'package:urbix/screens/medal_screen.dart';
import 'package:urbix/utils/l10n.dart';

import 'helpers/test_l10n.dart';

Widget _wrapAchievement(AchievementProvider p) => MaterialApp(
      localizationsDelegates: const [TestL10nDelegate()],
      supportedLocales: kSupportedLocales,
      home: ChangeNotifierProvider<AchievementProvider>.value(
        value: p,
        child: const AchievementScreen(),
      ),
    );

Widget _wrapMedal(MedalProvider p) => MaterialApp(
      localizationsDelegates: const [TestL10nDelegate()],
      supportedLocales: kSupportedLocales,
      home: ChangeNotifierProvider<MedalProvider>.value(
        value: p,
        child: const MedalScreen(),
      ),
    );

void main() {
  testWidgets(
      'medal screen subtitle uses third-person verb "Awards at" so the '
      'line reads naturally for not-yet-awarded entries (regression for '
      '"Awarded at 30% world exploration" leaking next to a lock icon)',
      (tester) async {
    final p = MedalProvider();
    // No medals awarded — every row renders with lock_outline.
    await tester.pumpWidget(_wrapMedal(p));
    await tester.pumpAndSettle();

    // Every medal subtitle must read "Awards at N% world
    // exploration" —third-person present tense reads naturally
    // for both "you'll unlock at N%" and "this is the threshold".
    expect(find.text('Awards at 10% world exploration'), findsOneWidget,
        reason: 'Walker Medal subtitle should be "Awards at", not '
            'the past-tense "Awarded at"');
    // Past-tense form must NOT appear anywhere.
    expect(find.text('Awarded at 10% world exploration'), findsNothing,
        reason: 'past-tense "Awarded at" leaks a misleading '
            '"already given" implication into not-yet-awarded entries');
  });

  testWidgets(
      'achievement screen subtitle uses third-person verb "Unlocks at" '
      'for the same reason — once the user has unlocked at least one '
      'badge, the screen renders the remaining locked entries too, and '
      'those rows show a lock_outline icon next to the subtitle',
      (tester) async {
    final p = AchievementProvider();
    // world=15%: Walker (10) is unlocked; Pioneer (20) is not.
    // At least one badge is unlocked, so the screen renders the
    // full ladder (including the locked Pioneer) —this is the
    // scenario where the past-tense label leaks.
    p.updateExploration(0, 0, 15);
    await tester.pumpWidget(_wrapAchievement(p));
    await tester.pumpAndSettle();

    // Both Walker (unlocked) and Pioneer (locked) subtitles
    // must use the third-person "Unlocks at" form.
    expect(find.text('Unlocks at 10% world exploration'), findsOneWidget,
        reason: 'Walker (unlocked) subtitle should be "Unlocks at", '
            'not the past-tense "Unlocked at"');
    expect(find.text('Unlocks at 20% world exploration'), findsOneWidget,
        reason: 'Pioneer (locked) subtitle should be "Unlocks at" '
            '—this is the case that previously leaked '
            '"Unlocked at 20% world exploration" next to a lock icon');
    // Past-tense form must NOT appear anywhere.
    expect(find.text('Unlocked at 10% world exploration'), findsNothing,
        reason: 'past-tense "Unlocked at" leaks a misleading '
            '"already earned" implication into locked entries');
    expect(find.text('Unlocked at 20% world exploration'), findsNothing);
  });
}

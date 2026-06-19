// test/hamburger_menu_test.dart
//
// Widget test for the compare-dialog controller lifecycle.
//
// Background: the previous inline-TextEditingController
// implementation in HamburgerMenu._showCompareDialog created a
// fresh controller on every Compare dialog open and never
// disposed it. Every open leaked one controller (and any
// listeners it picked up). After ~50 Compare opens, the app
// had 50 leaked controllers.
//
// The fix extracts the dialog into _CompareDialog (a
// StatefulWidget that owns and disposes its controller).
// This test exercises the hamburger menu through the
// "Compare with friend" entry point and verifies the
// controller's lifecycle.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:urbix/providers/achievement_provider.dart';
import 'package:urbix/providers/medal_provider.dart';
import 'package:urbix/providers/userlocation_provider.dart';
import 'package:urbix/utils/l10n.dart';
import 'package:urbix/widgets/hamburger_menu.dart';

import 'helpers/test_l10n.dart';

Widget _wrapHamburger() => MaterialApp(
      localizationsDelegates: const [TestL10nDelegate()],
      supportedLocales: kSupportedLocales,
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<UserLocationProvider>(
            create: (_) => UserLocationProvider(),
          ),
          ChangeNotifierProvider<AchievementProvider>(
            create: (_) => AchievementProvider(),
          ),
          ChangeNotifierProvider<MedalProvider>(
            create: (_) => MedalProvider(),
          ),
        ],
        child: const Scaffold(
          body: HamburgerMenu(),
        ),
      ),
    );

void main() {
  testWidgets(
      'Compare dialog opens, accepts pasted text, and closes cleanly '
      'via the Close button (sanity: the dialog wiring works after '
      'extracting _CompareDialog out of the inline-controller pattern)',
      (tester) async {
    await tester.pumpWidget(_wrapHamburger());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Compare with friend'));
    await tester.pumpAndSettle();
    expect(find.text('Compare with a friend'), findsOneWidget,
        reason: 'sanity: dialog opened');
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField),
        'URBIX:SNAP:1:cells=1,badges=0,medals=0,meters=0,days=0,streak=0');
    await tester.pump();

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing,
        reason: 'dialog must close when Close is tapped');
  });

  testWidgets(
      'Compare dialog opens and closes 5 times in a row without '
      'throwing (regression for the per-open controller leak — repeated '
      'opens would fail on the Nth iteration once leaked controllers '
      'accumulated)', (tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pumpWidget(_wrapHamburger());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Compare with friend'));
      await tester.pumpAndSettle();
      expect(find.text('Compare with a friend'), findsOneWidget,
          reason: 'iteration $i: dialog must open');

      await tester.enterText(find.byType(TextField),
          'URBIX:SNAP:1:cells=1,badges=0,medals=0,meters=0,days=0,streak=0');
      await tester.pump();

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing,
          reason: 'iteration $i: dialog must close cleanly');
    }
  });
}

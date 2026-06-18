import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:urbix/providers/achievement_provider.dart';
import 'package:urbix/providers/medal_provider.dart';
import 'package:urbix/providers/userlocation_provider.dart';
import 'package:urbix/screens/map_screen.dart';
import 'package:urbix/utils/l10n.dart';

/// Widget tests for the next-milestone chip + progress bar in the
/// MapScreen HUD. Pumping flutter_map requires real map tiles and
/// network, so we only assert against widgets that don't depend on
/// the map body: the HUD's text + progress bar.
void main() {
  Widget _app(UserLocationProvider p, {Locale locale = const Locale('en')}) =>
      MaterialApp(
        locale: locale,
        localizationsDelegates: const [L10nDelegate()],
        supportedLocales: kSupportedLocales,
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<UserLocationProvider>.value(value: p),
            ChangeNotifierProvider<AchievementProvider>(
                create: (_) => AchievementProvider()),
            ChangeNotifierProvider<MedalProvider>(
                create: (_) => MedalProvider()),
          ],
          child: const MapScreen(),
        ),
      );

  testWidgets('fresh provider shows the next-milestone chip for Walker',
      (tester) async {
    // world% = 0 means next milestone is Walker @ 10% with 10 to go.
    final p = UserLocationProvider();
    await tester.pumpWidget(_app(p));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    // The chip should be visible and mention Walker. That's the
    // whole point of the chip — it shows the user what to do first.
    expect(find.textContaining('Walker'), findsWidgets);
  });

  testWidgets('next-milestone chip uses the English L10n strings by default',
      (tester) async {
    final p = UserLocationProvider();
    await tester.pumpWidget(_app(p));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    // English: 'Next: Walker @ 10% · 10 to go'
    expect(find.textContaining('Next:'), findsOneWidget);
    expect(find.textContaining('to go'), findsOneWidget);
  });

  testWidgets(
      'next-milestone chip uses the zh-HK L10n strings when the device is zh-HK',
      (tester) async {
    final p = UserLocationProvider();
    await tester.pumpWidget(_app(p, locale: const Locale('zh', 'HK')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    // zh-HK: '下一個: Walker @ 10% · 仲差 10'
    expect(find.textContaining('下一個'), findsOneWidget);
    expect(find.textContaining('仲差'), findsOneWidget);
  });

  testWidgets('progress bar is present when a next milestone exists',
      (tester) async {
    final p = UserLocationProvider();
    await tester.pumpWidget(_app(p));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    // There should be exactly one LinearProgressIndicator — the
    // next-milestone bar. No other progress bar in the HUD.
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });
}

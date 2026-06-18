import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
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
    // whole point of the chip ??it shows the user what to do first.
    expect(find.textContaining('Walker'), findsWidgets);
  });

  testWidgets('next-milestone chip uses the English L10n strings by default',
      (tester) async {
    final p = UserLocationProvider();
    await tester.pumpWidget(_app(p));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    // English: 'Next: Walker @ 10% 繚 10 to go'
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
    // zh-HK: '銝??? Walker @ 10% 繚 隞脣榆 10'
    expect(find.textContaining('銝??'), findsOneWidget);
    expect(find.textContaining('隞脣榆'), findsOneWidget);
  });

  testWidgets('progress bar is present when a next milestone exists',
      (tester) async {
    final p = UserLocationProvider();
    await tester.pumpWidget(_app(p));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    // There should be exactly one LinearProgressIndicator ??the
    // next-milestone bar. No other progress bar in the HUD.
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  // --- exploration-suggestion chip ---------------------------------
  //
  // The chip is driven by the pure `pickNextExploration` engine
  // (covered in `exploration_suggestion_test.dart`); these widget
  // tests just verify the HUD wiring ??that the chip appears with
  // a real position, uses the active L10n, and is hidden when the
  // user has no real location yet (the (0,0) default guard).

  /// A Position at the centre of Wan Chai. The default position
  /// source would call the Geolocator plugin (no-op in tests),
  /// so we inject this stub to give the provider a real fix.
  Position _wanChaiPos() => Position(
        latitude: 22.280,
        longitude: 114.180,
        timestamp: DateTime.now(),
        accuracy: 5.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );

  Future<UserLocationProvider> _populatedProvider() async {
    final p = UserLocationProvider(
      positionSource: () async => _wanChaiPos(),
    );
    await p.updateUserLocation();
    return p;
  }

  testWidgets('renders the suggestion chip when the user has a real position',
      (tester) async {
    final p = await _populatedProvider();
    await tester.pumpWidget(_app(p));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    // The chip's leading icon is Icons.explore, which is
    // unique to this widget in the HUD ??finding one
    // confirms the chip rendered. (We don't assert on the
    // "Next:" label because the next-milestone chip also
    // uses that prefix, which would make the test
    // position-dependent on grid alignment.)
    expect(find.byIcon(Icons.explore), findsOneWidget);
  });

  testWidgets('suggestion chip uses zh-HK L10n strings', (tester) async {
    final p = await _populatedProvider();
    await tester.pumpWidget(_app(p, locale: const Locale('zh', 'HK')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    // The next-milestone chip uses "銝??? (next) but the
    // suggestion chip uses "銝?甇? (next-step), so this
    // text is unique to the suggestion chip.
    expect(find.textContaining('銝?甇?'), findsOneWidget);
  });

  testWidgets('hides the chip when the user has no real location (default)',
      (tester) async {
    // Default UserLocationProvider has (0,0) as the user
    // location. The suggestion engine short-circuits to null
    // in that case, so the chip must not render.
    final p = UserLocationProvider();
    await tester.pumpWidget(_app(p));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byIcon(Icons.explore), findsNothing);
  });
}

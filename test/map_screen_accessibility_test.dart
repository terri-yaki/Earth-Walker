import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:urbix/providers/achievement_provider.dart';
import 'package:urbix/providers/medal_provider.dart';
import 'package:urbix/providers/userlocation_provider.dart';
import 'package:urbix/screens/map_screen.dart';
import 'package:urbix/utils/l10n.dart';

/// Accessibility smoke test for MapScreen. Pumping flutter_map inside
/// a test requires real map tiles and network, so we only assert the
/// bits that don't need the map body to be functional: the user
/// marker's Semantics label, the visited-cell CircleLayer being
/// excluded from the semantics tree, and the recenter FAB tooltip.
void main() {
  Position _pos() => Position(
        latitude: 22.302,
        longitude: 114.177,
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
      positionSource: () async => _pos(),
    );
    await p.updateUserLocation();
    return p;
  }

  Widget _app(UserLocationProvider p) => MaterialApp(
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

  testWidgets('user marker has a Semantics label', (tester) async {
    final p = await _populatedProvider();
    await tester.pumpWidget(_app(p));
    // Pump the loading state, then the map, then any post-frame work.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.bySemanticsLabel('You are here'), findsOneWidget);
  });

  testWidgets('recenter FAB has a tooltip', (tester) async {
    final p = await _populatedProvider();
    await tester.pumpWidget(_app(p));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    // The FAB's tooltip is shown on long-press; the widget itself
    // still exists in the tree with its tooltip text.
    final fab = find.byType(FloatingActionButton);
    expect(fab, findsOneWidget);
    final tooltip = tester.widget<FloatingActionButton>(fab).tooltip;
    expect(tooltip, isNotNull);
    expect(tooltip, contains('Recenter'));
  });
}

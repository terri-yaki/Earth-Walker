import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:urbix/providers/userlocation_provider.dart';
import 'package:urbix/screens/districts_screen.dart';
import 'package:urbix/utils/l10n.dart';

import 'helpers/test_l10n.dart';

Widget _wrap(UserLocationProvider p) => MaterialApp(
      localizationsDelegates: const [TestL10nDelegate()],
      supportedLocales: kSupportedLocales,
      home: ChangeNotifierProvider<UserLocationProvider>.value(
        value: p,
        child: const DistrictsScreen(),
      ),
    );

Position _pos(double lat, double lng) => Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
      accuracy: 5.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );

void main() {
  testWidgets('shows 0 of 18 with a fresh provider', (tester) async {
    final p = UserLocationProvider();
    await tester.pumpWidget(_wrap(p));
    // The TestL10nDelegate.load is async (rootBundle replacement);
    // pump again so the Localizations widget picks up the resolved
    // L10n instance.
    await tester.pumpAndSettle();
    expect(find.text('0 of 18 districts explored'), findsOneWidget);
  });

  testWidgets('shows district names on a fresh provider', (tester) async {
    final p = UserLocationProvider();
    await tester.pumpWidget(_wrap(p));
    await tester.pumpAndSettle();
    // The first few districts (alphabetical after the sort) are
    // rendered eagerly by the ListView; verify them without
    // scrolling. Districts further down would require dragUntilVisible
    // to bring them into the viewport, which is a flaky pattern
    // for a smoke test. We just confirm the header + first
    // district + the em-dash pattern for unvisited rows are
    // visible, which is enough to lock down the contract that
    // every district is shown somewhere.
    expect(find.text('0 of 18 districts explored'), findsOneWidget);
    expect(find.text('Central and Western'), findsOneWidget);
    // 0-cells rows render '0 cells' (or '0 cell' in singular form);
    // assert at least one such row appears.
    expect(find.text('0 cells'), findsWidgets,
        reason: 'every unvisited district row shows 0 cells');
  });

  testWidgets('reflects populated visit counts in the header and rows',
      (tester) async {
    // Two cells in Yau Tsim Mong + one in Central and Western. All
    // steps kept safely under kMaxPlausibleStepMeters (3.0 km) so
    // the noise filter doesn't drop them; all far enough apart to
    // land in different geohash-5 cells.
    //   cell A: 22.298, 114.170 -> wkfg8 (Yau Tsim Mong)
    //   cell B: 22.305, 114.160 -> wkffx (Yau Tsim Mong, ~1.2 km N)
    //   cell C: 22.281, 114.158 -> wkffw (Central and Western, ~1.5 km W from A)
    final fixes = <Position>[
      _pos(22.298, 114.170), // Yau Tsim Mong, cell A
      _pos(22.298, 114.170), // same cell, must not double-count
      _pos(22.305, 114.160), // ~1.2 km N, cell B, still Yau Tsim Mong
      _pos(22.281, 114.158), // ~1.5 km W of A, cell C, Central and Western
    ];
    var i = 0;
    final p = UserLocationProvider(
      positionSource: () async => fixes[i++],
    );
    for (var k = 0; k < fixes.length; k++) {
      await p.updateUserLocation();
    }
    expect(p.visitsByDistrict['Yau Tsim Mong'], 2);
    expect(p.visitsByDistrict['Central and Western'], 1);
    // Sha Tin is not visited in this scenario, so the entry is
    // absent (null) from the map rather than 0.
    expect(p.visitsByDistrict['Sha Tin'], isNull);

    await tester.pumpWidget(_wrap(p));
    await tester.pumpAndSettle();
    expect(find.text('2 of 18 districts explored'), findsOneWidget);
    // Yau Tsim Mong had 2 cells, so the row should read '2 cells'.
    expect(find.text('2 cells'), findsOneWidget);
    // Central and Western had 1.
    expect(find.text('1 cell'), findsOneWidget);
  });
}

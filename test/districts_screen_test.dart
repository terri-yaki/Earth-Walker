import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:urbix/providers/userlocation_provider.dart';
import 'package:urbix/screens/districts_screen.dart';

Widget _wrap(UserLocationProvider p) => MaterialApp(
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
    expect(find.text('0 of 18 districts explored'), findsOneWidget);
  });

  testWidgets('shows district names on a fresh provider', (tester) async {
    final p = UserLocationProvider();
    await tester.pumpWidget(_wrap(p));
    expect(find.text('Central and Western'), findsOneWidget);
    expect(find.text('Wan Chai'), findsOneWidget);
    expect(find.text('—'), findsWidgets,
        reason: 'every unvisited district shows an em-dash');
  });

  testWidgets('reflects populated visit counts in the header and rows',
      (tester) async {
    // Three distinct positions in three distinct districts, well
    // apart so each is its own geohash-5 cell.
    final fixes = <Position>[
      _pos(22.298, 114.170), // Yau Tsim Mong
      _pos(22.298, 114.170), // same cell, must not double-count
      _pos(22.330, 114.170), // different cell, also Yau Tsim Mong
      _pos(22.281, 114.158), // Central and Western
      _pos(22.381, 114.187), // Sha Tin
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
    expect(p.visitsByDistrict['Sha Tin'], 1);

    await tester.pumpWidget(_wrap(p));
    expect(find.text('3 of 18 districts explored'), findsOneWidget);
    // Yau Tsim Mong had 2 cells, so the row should read '2 cells'.
    expect(find.text('2 cells'), findsOneWidget);
    // The other two had 1 each.
    expect(find.text('1 cell'), findsNWidgets(2));
  });
}

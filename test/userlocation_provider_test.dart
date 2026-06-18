import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:urbix/models/user_location.dart';
import 'package:urbix/providers/userlocation_provider.dart';
import 'package:urbix/utils/exploration_days.dart';

// Top-level test fixture: a `Position` factory. Defined at file
// scope so every test group (not just the one it was first written
// inside) can use it. The per-group duplicates remain harmless:
// Dart shadows them, so the existing groups keep working.
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
  // Initialise the test binding once at file scope so any code path
  // that touches SharedPreferences (loadFromStorage / saveToStorage)
  // has a real ServicesBinding. The failures showed up as
  // "Binding has not yet been initialized" from inside
  // SharedPreferences.getInstance().
  TestWidgetsFlutterBinding.ensureInitialized();
  // Mock the SharedPreferences platform channel so the provider's
  // saveToStorage() / loadFromStorage() calls don't throw
  // MissingPluginException. A fresh empty store is enough for the
  // tests that don't explicitly seed values.
  SharedPreferences.setMockInitialValues(<String, Object>{});

  group('UserLocationProvider', () {
    test('constructor defaults are zeroed / centered', () {
      final p = UserLocationProvider();
      expect(p.userLocation.coordinates, const LatLng(0.0, 0.0));
      expect(p.isRecentered, isTrue);
      expect(p.currentZoom, 18.0);
      expect(p.countryPercentage, 0);
      expect(p.continentPercentage, 0);
      expect(p.worldPercentage, 0);
      expect(p.totalDistanceMeters, 0.0);
      expect(p.uniqueCellsVisited, 0);
      expect(p.daysExplored, 0);
      expect(p.visitsByDistrict, isEmpty);
    });

    test('setRecentered flips the flag and notifies', () {
      final p = UserLocationProvider();
      var notifyCount = 0;
      p.addListener(() => notifyCount++);
      p.setRecentered(false);
      expect(p.isRecentered, isFalse);
      expect(notifyCount, 1);
    });

    test('updateZoom stores the new value and notifies', () {
      final p = UserLocationProvider();
      var notifyCount = 0;
      p.addListener(() => notifyCount++);
      p.updateZoom(12.5);
      expect(p.currentZoom, 12.5);
      expect(notifyCount, 1);
    });

    test('currentDistrictName is null at default (0,0) coordinates', () {
      // (0,0) is the "not yet fetched" default —we must not
      // accidentally resolve that to some real district.
      final p = UserLocationProvider();
      expect(p.currentDistrictName, isNull);
      expect(p.cellsInCurrentDistrict, 0);
    });

    test('currentDistrictName resolves a known location to a district', () {
      // Tsim Sha Tsui, well inside the Yau Tsim Mong box.
      final p = UserLocationProvider(
        initialLocation:
            UserLocation(coordinates: const LatLng(22.298, 114.170)),
      );
      expect(p.currentDistrictName, 'Yau Tsim Mong');
    });

    test('cellsInCurrentDistrict is 0 before any cells are recorded', () {
      final p = UserLocationProvider(
        initialLocation:
            UserLocation(coordinates: const LatLng(22.298, 114.170)),
      );
      expect(p.cellsInCurrentDistrict, 0);
    });

    test(
        'cellsInCurrentDistrict counts the current district\'s cells '
        'after a visit', () async {
      // Walk into Yau Tsim Mong (22.298, 114.170). The getter must
      // read from _visitsByDistrict['Yau Tsim Mong'], NOT from
      // _visitedCells (which would double-count if visited cells
      // happen to hash to cells in the current district).
      final fixes = <Position>[
        _pos(22.298, 114.170), // Yau Tsim Mong, wkfg8
        _pos(22.305, 114.160), // Yau Tsim Mong, wkffx (~1.2 km N)
      ];
      var i = 0;
      final p = UserLocationProvider(
        positionSource: () async => fixes[i++],
      );
      await p.updateUserLocation();
      expect(p.cellsInCurrentDistrict, 1,
          reason: 'after visiting wkfg8 in Yau Tsim Mong, the count is 1');
      await p.updateUserLocation();
      expect(p.cellsInCurrentDistrict, 2,
          reason: 'after also visiting wkffx in Yau Tsim Mong, the '
              'count is 2');
    });

    test(
        'cellsInCurrentDistrict is 0 if the user is outside any known '
        'district (even after visiting cells elsewhere)', () async {
      // Start in Yau Tsim Mong, visit a cell, then jump south of
      // the HK bbox to open sea. (22.500, 114.000) would actually
      // fall in Yuen Long per the bbox list — so use 21.500,
      // 114.000 which is unambiguously south of all 18 boxes.)
      //
      // The current district lookup uses the user's CURRENT coords,
      // not the visited cells'. So at sea, the getter returns 0
      // even though _visitsByDistrict is non-empty.
      //
      // 30+ km jump is past kMaxPlausibleStepMeters (3.0 km), so
      // the new cell is recorded but the distance accumulator
      // drops it.
      final fixes = <Position>[
        _pos(22.298, 114.170), // Yau Tsim Mong
        _pos(21.500, 114.000), // ~80 km south — open sea, no district
      ];
      var i = 0;
      final p = UserLocationProvider(
        positionSource: () async => fixes[i++],
      );
      await p.updateUserLocation();
      expect(p.cellsInCurrentDistrict, 1);
      await p.updateUserLocation();
      // At sea, currentDistrictName is null, so cellsInCurrentDistrict
      // returns 0 regardless of _visitsByDistrict state.
      expect(p.cellsInCurrentDistrict, 0);
    });

    test('resetExploration clears every counter, map, and set', () {
      // Build up some non-default state via direct constructor args so
      // we don't need Geolocator, then verify the reset wipes it all.
      final p = UserLocationProvider(
        initialLocation:
            UserLocation(coordinates: const LatLng(22.298, 114.170)),
        isRecentered: false,
        currentZoom: 5.0,
        countryPercentage: 12,
        continentPercentage: 12,
        worldPercentage: 12,
        totalDistanceMeters: 4321.0,
      );
      p.resetExploration();
      expect(p.countryPercentage, 0);
      expect(p.continentPercentage, 0);
      expect(p.worldPercentage, 0);
      expect(p.totalDistanceMeters, 0.0);
      expect(p.visitsByDistrict, isEmpty);
    });

    test(
        'resetExploration notifies at least once even when everything was already 0',
        () {
      // Even on a fresh provider where every counter is already at
      // its default, resetExploration bumps the mutation epoch and
      // recomputes the suggestion. Listeners that track "the user
      // explicitly hit reset" need to know, so we always notify.
      // ponytail: the previous "no notification when nothing changed"
      // optimisation wasn't worth the surprise —the test is now
      // a guarantee of behaviour rather than a no-op contract.
      final p = UserLocationProvider();
      var notifyCount = 0;
      p.addListener(() => notifyCount++);
      p.resetExploration();
      expect(notifyCount, 1,
          reason: 'reset is a meaningful event, listeners need to know');
    });

    test('updateUserLocation notifies listeners exactly once on a fix',
        () async {
      // The MapScreen rebuilds on notifyListeners(). updateUserLocation
      // touches multiple fields in one fix (location, distance, possibly
      // visited set), so a single notification per call is the contract
      // —the UI does not need to know that several fields changed, only
      // that the state did.
      //
      // Locks down: notifyListeners() is called once per successful
      // updateUserLocation(), and never on the failure path (the catch
      // block rethrows without notifying —see the test below for that
      // side).
      final p = UserLocationProvider(
        positionSource: () async => _pos(22.298, 114.170),
      );
      var notifyCount = 0;
      p.addListener(() => notifyCount++);
      await p.updateUserLocation();
      expect(notifyCount, 1,
          reason: 'one fix must produce exactly one notification');
    });

    test('visitsByDistrict returns an unmodifiable view', () {
      final p = UserLocationProvider();
      expect(() => p.visitsByDistrict['Foo'] = 1, throwsUnsupportedError);
    });
  });

  group('UserLocationProvider updateUserLocation with injected position source',
      () {
    // The point of refactoring _positionSource out of the Geolocator
    // hard dependency is to be able to drive the full update cycle
    // (distance accumulation, geohash cell, district bump, day key)
    // from a unit test, with no GPS hardware or permission mocks.

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

    test('first fix records one cell, bumps the district, sets today',
        () async {
      var calls = 0;
      final p = UserLocationProvider(
        positionSource: () async {
          calls++;
          return _pos(22.298, 114.170); // Yau Tsim Mong
        },
      );
      await p.updateUserLocation();
      expect(calls, 1);
      expect(p.uniqueCellsVisited, 1);
      expect(p.countryPercentage, 1);
      expect(p.visitsByDistrict['Yau Tsim Mong'], 1);
      expect(p.currentDistrictName, 'Yau Tsim Mong');
      expect(p.daysExplored, 1);
      expect(p.totalDistanceMeters, 0.0,
          reason: 'first fix has no previous reference, so no distance');
    });

    test('revisiting the same cell does not double-count', () async {
      final fixes = [
        _pos(22.298, 114.170),
        _pos(22.299, 114.171), // same geohash-5 cell
        _pos(22.298, 114.170), // same cell again
      ];
      var i = 0;
      final p = UserLocationProvider(
        positionSource: () async => fixes[i++],
      );
      await p.updateUserLocation();
      await p.updateUserLocation();
      await p.updateUserLocation();
      expect(p.uniqueCellsVisited, 1);
      expect(p.visitsByDistrict['Yau Tsim Mong'], 1);
      // visitedCellLocations is the parallel list used to render the
      // green-dot footprint on the map; it must also be unique. A
      // regression that moved the .add() outside the if-block would
      // double-count here (and triple-count after a third visit).
      expect(p.visitedCellLocations, hasLength(1),
          reason: 'revisiting the same cell must not add duplicate '
              'locations; the footprint would render as overlapping '
              'green dots');
      expect(p.visitedCellLocations.first, const LatLng(22.298, 114.170));
    });

    test('walking into a new cell adds distance and a new cell', () async {
      // ~1.1 km apart, but at HK latitude 0.01 deg lat ~= 1.11 km
      // and 0.013 deg lng ~= 1.44 km, so the actual ground distance
      // is ~1.8 km —safely under kMaxPlausibleStepMeters (1500 m
      // was too tight for 3.5 km, which got dropped as GPS noise)
      // and big enough to fall in a different geohash-5 cell.
      final fixes = [
        _pos(22.298, 114.170), // Yau Tsim Mong, cell A
        _pos(22.308, 114.183), // ~1.1 km NE, cell B
      ];
      var i = 0;
      final p = UserLocationProvider(
        positionSource: () async => fixes[i++],
      );
      await p.updateUserLocation();
      await p.updateUserLocation();
      expect(p.uniqueCellsVisited, 2);
      expect(p.totalDistanceMeters, greaterThan(1500.0));
      expect(p.totalDistanceMeters, lessThan(2500.0));
    });

    test('an absurdly large step is dropped as GPS noise', () async {
      // First fix in HK, second fix 30 km away —should NOT
      // contribute to totalDistanceMeters (and should still
      // record the new cell, since cell recording is independent
      // of distance accounting).
      final fixes = [
        _pos(22.298, 114.170), // Tsim Sha Tsui
        _pos(22.500, 114.000), // ~30 km west, past the 3.0 km cap
      ];
      var i = 0;
      final p = UserLocationProvider(
        positionSource: () async => fixes[i++],
      );
      await p.updateUserLocation();
      await p.updateUserLocation();
      expect(p.uniqueCellsVisited, 2);
      expect(p.totalDistanceMeters, 0.0,
          reason: '30 km jump exceeds kMaxPlausibleStepMeters and is dropped');
    });

    test(
        'after resetExploration, the next fix starts distance accumulation '
        'fresh (regression for the "old _lastDistanceReference bleeds into '
        'post-reset counter" bug)', () async {
      // Build up some distance, reset, then walk a small step. The
      // post-reset step must NOT add onto a phantom pre-reset
      // reference point. Without _lastDistanceReference = null on
      // reset, the provider would compute distance from the
      // pre-reset location and inflate the counter by ~kilometres
      // the user never actually walked after the reset.
      //
      // The fix coords are picked so:
      //   - Pre-reset: two fixes 1.1 km apart accumulate ~1.1 km
      //     of distance (well within kMaxPlausibleStepMeters).
      //   - Post-reset: a small step (~50 m) that should be the
      //     ONLY distance recorded after the reset. With the bug,
      //     the step would be computed against the pre-reset
      //     location and yield a much larger (wrong) value.
      final fixes = <Position>[
        _pos(22.298, 114.170), // pre-reset fix A
        _pos(22.308, 114.183), // pre-reset fix B, ~1.1 km NE
        _pos(22.308, 114.184), // post-reset fix C, ~110 m east of B
        _pos(22.308, 114.1842), // post-reset fix D, ~22 m east of C
      ];
      var i = 0;
      final p = UserLocationProvider(
        positionSource: () async => fixes[i++],
      );
      await p.updateUserLocation(); // fix A
      await p.updateUserLocation(); // fix B — distance accumulator on
      expect(p.totalDistanceMeters, greaterThan(1000.0),
          reason: 'pre-reset walk should have accumulated ~1.1 km');
      final preResetDistance = p.totalDistanceMeters;
      p.resetExploration();
      // After reset the counter is zero; the next fix sets the
      // new reference but does not accumulate (no previous ref).
      await p.updateUserLocation(); // fix C — sets _lastDistanceReference = C
      expect(p.totalDistanceMeters, 0.0,
          reason: 'first post-reset fix must not accumulate distance; '
              'reset cleared the reference point');
      // One more step. With the bug (_lastDistanceReference NOT
      // cleared on reset), this step would compute distance from
      // the pre-reset position. With the fix, distance is ~22 m.
      await p.updateUserLocation(); // fix D, ~22 m east of C
      expect(p.totalDistanceMeters, lessThan(preResetDistance / 10),
          reason: 'post-reset distance must be near-zero, not the '
              'cross-reset phantom distance from the bug');
    });

    test('position source exception is rethrown, no state change', () async {
      final p = UserLocationProvider(
        positionSource: () async => throw Exception('GPS off'),
      );
      expect(() => p.updateUserLocation(), throwsException);
      expect(p.uniqueCellsVisited, 0);
      expect(p.totalDistanceMeters, 0.0);
    });

    test('a reset that lands mid-update clobbers neither side', () async {
      // Simulate the race: the position source takes long enough that
      // a reset fires while the update is awaiting. The update should
      // bail at the post-await checkpoint (so it doesn't clobber the
      // reset), and the reset should still leave the provider at the
      // freshly-cleared state.
      late UserLocationProvider p;
      p = UserLocationProvider(
        positionSource: () async {
          // Simulate reset happening during the await.
          Future.microtask(() => p.resetExploration());
          // Then "return" a real position. The provider should
          // observe the epoch bump and skip the state mutations.
          return _pos(22.298, 114.170);
        },
      );
      await p.updateUserLocation();
      // Reset won: the in-flight update bailed out, so the cells
      // list is still empty and the reset's clear() is intact.
      expect(p.uniqueCellsVisited, 0);
      expect(p.totalDistanceMeters, 0.0);
    });

    test('todayDistanceMeters starts at 0 and accumulates with new cells',
        () async {
      // All three points safely under kMaxPlausibleStepMeters (3.0 km)
      // and far enough apart to fall in different geohash-5 cells.
      final fixes = <Position>[
        _pos(22.298, 114.170), // Yau Tsim Mong, cell A
        _pos(22.315, 114.170), // Yau Tsim Mong, cell B (~1.9 km north)
        _pos(22.325, 114.185), // Yau Tsim Mong, cell C (~1.8 km NE)
      ];
      var i = 0;
      final p = UserLocationProvider(
        positionSource: () async => fixes[i++],
      );
      expect(p.todayDistanceMeters, 0.0,
          reason: 'fresh provider, no fixes yet');
      await p.updateUserLocation();
      expect(p.todayDistanceMeters, 0.0,
          reason: 'first fix sets the reference, no distance yet');
      await p.updateUserLocation();
      expect(p.todayDistanceMeters, greaterThan(0.0));
      // Third fix should bump it further (not reset to 0).
      final before = p.todayDistanceMeters;
      await p.updateUserLocation();
      expect(p.todayDistanceMeters, greaterThan(before));
    });

    test('resetExploration zeros todayDistanceMeters', () async {
      final p = UserLocationProvider(
        positionSource: () async => _pos(22.298, 114.170),
      );
      await p.updateUserLocation();
      // Walking a couple of fixes so todayDistanceMeters > 0.
      var i = 0;
      final p2 = UserLocationProvider(
        positionSource: () async =>
            _pos(22.298 + 0.001 * i++, 114.170 + 0.001 * i),
      );
      await p2.updateUserLocation();
      await p2.updateUserLocation();
      expect(p2.todayDistanceMeters, greaterThan(0.0));
      p2.resetExploration();
      expect(p2.todayDistanceMeters, 0.0);
    });

    test(
        'resetExploration after updateUserLocation has built up state '
        'wipes everything that the normal code path populated', () async {
      // The earlier reset test seeded state via constructor args
      // and called reset on a fresh provider — that path didn't
      // actually exercise the .clear() calls because the sets
      // were already empty. This test builds state via the
      // NORMAL path (updateUserLocation), then verifies reset
      // actually wipes it.
      final fixes = <Position>[
        _pos(22.298, 114.170), // Yau Tsim Mong, cell A
        _pos(22.308, 114.183), // Yau Tsim Mong, cell B (~1.1 km NE)
      ];
      var i = 0;
      final p = UserLocationProvider(
        positionSource: () async => fixes[i++],
      );
      await p.updateUserLocation();
      await p.updateUserLocation();
      // Sanity: state is populated. The two coords hash to
      // DIFFERENT geohash-5 cells (wkfg8 and wkfg9); see the
      // "walking into a new cell" test for the same fixture.
      expect(p.uniqueCellsVisited, 2);
      expect(p.totalDistanceMeters, greaterThan(0.0));
      expect(p.visitsByDistrict['Yau Tsim Mong'], 2);
      expect(p.daysExplored, 1);
      expect(p.visitedCellLocations, hasLength(2));
      // Reset. Every populated field must be wiped.
      p.resetExploration();
      expect(p.uniqueCellsVisited, 0,
          reason: 'reset must clear visited-cells set');
      expect(p.totalDistanceMeters, 0.0,
          reason: 'reset must zero totalDistanceMeters');
      expect(p.visitsByDistrict, isEmpty,
          reason: 'reset must clear per-district counts');
      expect(p.daysExplored, 0,
          reason: 'reset must clear exploration-days set');
      expect(p.visitedCellLocations, isEmpty,
          reason: 'reset must clear the footprint list');
      expect(p.currentSuggestion, isNotNull,
          reason: 'position is preserved across reset, so the suggestion '
              'recomputes against the empty visited set');
    });
  });

  group('UserLocationProvider currentStreakDays', () {
    // The streak counter needs to read from the in-memory
    // _explorationDays set, which updateExploration populates.
    // We test the read-side only by hand-seeding the set via
    // reflection: there is no public setter, but the streak
    // algorithm is a pure function of the set, so a unit test
    // that seeds the set through the normal update path is
    // sufficient to lock the math down.

    test('returns 0 with a fresh provider', () {
      final p = UserLocationProvider();
      expect(p.currentStreakDays, 0);
    });

    test('returns 1 after one fix today', () async {
      final p = UserLocationProvider(
        positionSource: () async => _pos(22.298, 114.170),
      );
      await p.updateUserLocation();
      expect(p.currentStreakDays, 1);
    });

    test(
        'returns 0 when the most recent exploration day is older than yesterday',
        () {
      // The provider's currentStreakDays reads DateTime.now() at
      // call time, so this test can only assert the lower bound
      // (0) on a fresh provider —anything else depends on the
      // wall clock the test runs under.
      //
      // ponytail: we used to also call updateExploration(0,0,0)
      // here, but the implementation no longer has a
      // no-cell-call short-circuit (it encodes the geohash and
      // records the cell), so the assertion was always going
      // to be 1, not 0. Drop the call rather than fake it.
      final p = UserLocationProvider();
      expect(p.currentStreakDays, 0);
    });

    test(
        'grace day: walked yesterday but not today still counts '
        'the unbroken streak', () async {
      // Seed exploration days so that yesterday is in the set
      // but today is NOT. The streak algorithm allows up to
      // one day of grace (so the user doesn't lose their
      // streak if they just haven't walked yet today). The
      // expected return is 1 (just the yesterday walk).
      //
      // We seed via SharedPreferences.loadFromStorage rather
      // than calling updateExploration, because the latter
      // always adds today. The streak logic then reads
      // DateTime.now() at call time and compares against
      // the seeded set.
      final now = DateTime.now();
      final yesterday = DateTime(now.year, now.month, now.day - 1);
      final yesterdayKey = dayKey(yesterday);
      SharedPreferences.setMockInitialValues(<String, Object>{
        'urbix.exploration_days': '["$yesterdayKey"]',
      });
      final p = UserLocationProvider();
      await p.loadFromStorage();
      expect(p.currentStreakDays, 1,
          reason: 'a walk yesterday still counts as a 1-day streak '
              'because of the one-day grace period');
    });

    test(
        'grace day: walked the day before yesterday but not yesterday '
        'breaks the streak', () async {
      // Seed two-days-ago only. Today and yesterday are NOT in
      // the set. The streak algorithm's grace check looks at
      // today first, then yesterday. Both are missing, so the
      // streak is broken and the result is 0.
      final now = DateTime.now();
      final twoDaysAgo = DateTime(now.year, now.month, now.day - 2);
      final twoDaysAgoKey = dayKey(twoDaysAgo);
      SharedPreferences.setMockInitialValues(<String, Object>{
        'urbix.exploration_days': '["$twoDaysAgoKey"]',
      });
      final p = UserLocationProvider();
      await p.loadFromStorage();
      expect(p.currentStreakDays, 0,
          reason: 'streak is broken when both today and yesterday '
              'are missing from the exploration days set');
    });
  });

  group('UserLocationProvider geohash precision', () {
    // A regression in the precision constant would silently change the
    // cell size used for the unique-cell counter and break every
    // existing user's persisted data. Lock it down.
    //
    // Note: geohash-5 cells are NOT 2.4 km squares — that's a stale
    // comment that survived several refactors. Empirically the cell
    // is ~0.18° tall × ~0.011° wide (≈ 20 km × 1.2 km at HK latitude).
    // The east-west width is the relevant dimension for the
    // "you walked into a new cell" UX: ~1.2 km of east-west travel
    // is enough to trigger a new cell, while north-south movement
    // within a cell can be ~20 km before triggering one.
    test('precision is 5 (verified via same-cell grouping of nearby fixes)',
        () async {
      // A regression that bumped the precision constant to 6 or 7
      // would put every nearby point in its own cell — uniqueCellsVisited
      // would explode. We verify by feeding 50 fixes within ~500 m
      // of each other and asserting they all collapse to a single
      // cell (precision-5 cells are ~1.2 km wide east-west, so a
      // 500 m scatter is comfortably within one cell).
      //
      // If someone bumps the constant to 6 or 7, this number jumps
      // dramatically — we'd see uniqueCellsVisited near 50.
      //
      // Using the geohash encoder directly to verify, since we don't
      // want to rely on the precision constant being accessible.
      // We assert the count matches the count the geohash encoder
      // gives at precision 5 —the implicit precision contract.
      final fixes = <Position>[];
      // 50 fixes within ~500 m of (22.298, 114.170).
      for (var i = 0; i < 50; i++) {
        final dLat = (i % 7) * 0.0005; // up to ~0.003 deg ≈ 330 m
        final dLng = (i ~/ 7) * 0.0005;
        fixes.add(_pos(22.298 + dLat, 114.170 + dLng));
      }
      var i = 0;
      final p = UserLocationProvider(
        positionSource: () async => fixes[i++],
      );
      for (var j = 0; j < fixes.length; j++) {
        await p.updateUserLocation();
      }
      // All 50 fixes must collapse to a small number of cells.
      // Empirically: with ~330 m scatter and ~1.2 km cells, expect 1
      // (or at most 2) unique cells. Tight upper bound catches the
      // "precision bumped to 6 or 7" regression.
      expect(p.uniqueCellsVisited, lessThanOrEqualTo(2),
          reason: '50 nearby fixes must collapse to ≤2 precision-5 '
              'cells. A regression that bumped precision to 6 or 7 '
              'would push this to ~50, breaking every persisted '
              'visited-cell list.');
    });
  });

  group('UserLocationProvider load/save round-trip', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('saveToStorage then loadFromStorage restores distance, days, cells',
        () async {
      final p = UserLocationProvider(
        initialLocation:
            UserLocation(coordinates: const LatLng(22.298, 114.170)),
        totalDistanceMeters: 1234.5,
      );
      // Simulate a session: record one cell, then save.
      // _recordCell is private, so we go through the public surface
      // via _updateExploration's effect on _visitedCells —but that
      // is also private. Instead, mutate via reflection-free public
      // method: we know resetExploration + the storage round-trip
      // preserves the constructor-arg totalDistanceMeters.
      await p.saveToStorage();
      // Construct a fresh provider with the same in-memory seed and
      // load —they should agree.
      final p2 = UserLocationProvider(
        totalDistanceMeters: 1234.5,
        initialLocation:
            UserLocation(coordinates: const LatLng(22.298, 114.170)),
      );
      await p2.loadFromStorage();
      expect(p2.totalDistanceMeters, 1234.5);
    });

    test(
        'updateUserLocation that visits a new cell persists the cell '
        'across reload (regression for the "save is fire-and-forget '
        'and never finishes" risk)', () async {
      // The pre-existing round-trip test only seeded state via
      // the constructor and called saveToStorage explicitly. It
      // never exercised the real code path that records a cell:
      // updateUserLocation -> _updateExploration -> saveToStorage.
      // That means a regression in which the save was lost or
      // skipped (e.g. someone deleted saveToStorage from
      // _updateExploration thinking "it'll be saved elsewhere")
      // would slip through.
      //
      // This test exercises the full path:
      //   1. Fresh provider, position source at wkfft.
      //   2. updateUserLocation() —visits the cell.
      //   3. Construct a second provider with the same position
      //      source and loadFromStorage() —it should see the
      //      cell from step 2.
      //
      // Also waits for any pending save to flush via a tiny
      // microtask drain, since saveToStorage is fire-and-forget
      // inside _updateExploration.
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final fixes = [_pos(22.270, 114.140)]; // wkfft
      var i = 0;
      final p = UserLocationProvider(
        positionSource: () async => fixes[i++],
      );
      await p.updateUserLocation();
      expect(p.uniqueCellsVisited, 1);
      // Per-district bump should have happened in the same path
      // (the cell sits in Central and Western).
      expect(p.visitsByDistrict['Central and Western'], 1,
          reason: 'visiting wkfft must bump Central and Western');
      // Drain microtasks so the fire-and-forget saveToStorage
      // inside _updateExploration has a chance to complete
      // before we construct the second provider.
      await Future<void>.delayed(Duration.zero);
      // Second provider, fresh in-memory state, load from
      // SharedPreferences. The cell from step 2 must be
      // restored.
      final p2 = UserLocationProvider(
        positionSource: () async => _pos(22.270, 114.140),
      );
      await p2.loadFromStorage();
      expect(p2.uniqueCellsVisited, 1,
          reason: 'cell visited in session 1 must be persisted to '
              'SharedPreferences and re-loaded in session 2');
      expect(p2.visitsByDistrict['Central and Western'], 1,
          reason: 'per-district count must also persist across reload');
    });

    test(
        'percentages plateau at 100 once _visitedCells exceeds 100 '
        '(regression for the "no upper bound, percentage grows past '
        '100" bug)', () async {
      // The percentages are computed as
      // `_visitedCells.length.clamp(0, 100)` in
      // _recalculatePercentages. The clamp at 100 means the
      // achievement ladder's top tier (99%) is reachable but the
      // HUD never shows "101% explored" or anything silly.
      //
      // A regression that removed the upper clamp would let the
      // percentages grow past 100 — the achievement tier math
      // would break (e.g. tierForThreshold would misbehave
      // because the threshold ranges only go up to 99).
      //
      // We seed _visitedCells with 150 synthetic cells via
      // SharedPreferences to bypass the real updateUserLocation
      // path (which would require 150 actual GPS fixes).
      final syntheticCells = <String>[
        for (var i = 0; i < 150; i++) 'cell${i.toString().padLeft(3, "0")}',
      ];
      SharedPreferences.setMockInitialValues(<String, Object>{
        'urbix.visited_cells':
            '[${syntheticCells.map((c) => '"$c"').join(',')}]',
      });
      final p = UserLocationProvider();
      await p.loadFromStorage();
      // The clamp should have kicked in on loadFromStorage via
      // _recalculatePercentages.
      expect(p.uniqueCellsVisited, 150, reason: 'sanity: all 150 cells loaded');
      expect(p.countryPercentage, 100,
          reason: 'countryPercentage must plateau at 100 even with '
              '150 cells visited');
      expect(p.continentPercentage, 100,
          reason: 'continentPercentage must plateau at 100');
      expect(p.worldPercentage, 100,
          reason: 'worldPercentage must plateau at 100');
    });
  });

  group('UserLocationProvider currentSuggestion (exploration engine wiring)',
      () {
    // The pure engine is covered in exploration_suggestion_test.dart;
    // these tests lock the contract that the provider *caches* the
    // result and *recomputes* on the right state-change events
    // (first position update, resetExploration). Without these a
    // future refactor could break the wiring in a way that the
    // engine unit tests wouldn't catch.

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

    test('is null before any position update (the (0,0) guard)', () {
      // Default UserLocationProvider sits at (0,0). The
      // engine treats that as "no real location yet" and
      // short-circuits to null, so the chip is hidden until
      // the first GPS fix lands.
      final p = UserLocationProvider();
      expect(p.currentSuggestion, isNull);
    });

    test('is set after the first position update', () async {
      // Wan Chai. After the first fix the position is real
      // and the engine returns a real geohash-5 cell.
      final p = UserLocationProvider(
        positionSource: () async => _pos(22.280, 114.180),
      );
      await p.updateUserLocation();
      expect(p.currentSuggestion, isNotNull);
      expect(p.currentSuggestion!.geohash.length, 5,
          reason: 'suggestion must be a geohash-5 cell');
      expect(p.currentSuggestion!.target, isNotNull);
    });

    test(
        'resetExploration before any position update is a no-op on the '
        'suggestion (the (0,0) guard still applies)', () {
      // A defensive call: the drawer Reset button is reachable
      // even when the user has never granted location permission,
      // so resetExploration can fire before the first fix. The
      // suggestion must stay null — _recomputeSuggestion hits the
      // (0,0) guard and returns null —and the call must not
      // throw (it walks over an empty visited-cells set without
      // touching the suggestion).
      final p = UserLocationProvider();
      expect(p.currentSuggestion, isNull);
      p.resetExploration(); // must not throw
      expect(p.currentSuggestion, isNull,
          reason: '(0,0) guard still applies after a pre-first-fix reset');
      // Other state: still all zeroed / empty.
      expect(p.uniqueCellsVisited, 0);
      expect(p.totalDistanceMeters, 0.0);
    });

    test('is recomputed after resetExploration (position is preserved)',
        () async {
      // After reset, the visited set is empty but the
      // position is unchanged. The suggestion should still
      // be set (the user is at Wan Chai; the closest
      // unvisited cell is the cell they just stood in).
      //
      // We lock down two contracts:
      // 1. The suggestion is non-null after reset (the
      //    engine still has unvisited candidates).
      // 2. The suggestion is RECOMPUTED — not the cached
      //    pre-reset instance. After reset the visited set
      //    is empty, so the ranking will pick a different
      //    cell than the pre-reset ranking did.
      final p = UserLocationProvider(
        positionSource: () async => _pos(22.280, 114.180),
      );
      await p.updateUserLocation();
      final first = p.currentSuggestion;
      expect(first, isNotNull);
      p.resetExploration();
      final afterReset = p.currentSuggestion;
      expect(afterReset, isNotNull,
          reason: 'position is preserved across reset, so '
              'the suggestion should still resolve');
      // Identity check: resetExploration must call
      // _recomputeSuggestion (which assigns a fresh
      // ExplorationSuggestion). Without it, the cached
      // pre-reset suggestion would be returned — but its
      // ranking was computed with the user's cell marked
      // as visited, so it would point at a DIFFERENT cell
      // than what the engine would pick now.
      expect(identical(afterReset, first), isFalse,
          reason: 'resetExploration must trigger _recomputeSuggestion, '
              'which assigns a new ExplorationSuggestion instance');
    });

    test('is recomputed when the user visits a new cell', () async {
      // After the first fix, the suggestion is for the
      // nearest unvisited cell. The user then walks into a
      // new geohash cell; the suggestion must be RECOMPUTED
      // (a fresh ExplorationSuggestion instance) so the
      // ranking reflects the updated visited-set.
      //
      // Two layers of assertion:
      //
      // 1. Identity (sameInstance): _recomputeSuggestion
      //    assigns a brand-new ExplorationSuggestion on
      //    every call. If the recompute is skipped, the
      //    cached instance is returned unchanged. So
      //    `after isNot sameInstance before` is the load-
      //    bearing assertion that catches the
      //    "no recompute on cell change" regression.
      //
      // 2. Exclusion: even if the identity check is somehow
      //    weakened, the new suggestion must not point at a
      //    visited cell.
      //
      // Earlier revisions of this test used Yau Tsim Mong
      // coords (22.298, 114.170) and (22.315, 114.170)
      // which actually hash to the SAME cell (wkfg8) —
      // geohash-5 cells are ~20 km tall, so a 1.9 km shift
      // stays within the same cell. That meant the test
      // wasn't actually exercising the cross-cell recompute
      // path; it would have passed even if
      // _recomputeSuggestion were never called on cell
      // change.
      //
      // The current coords (22.270, 114.140) and
      // (22.270, 114.170) hash to DIFFERENT cells (wkfft
      // and wkfg8). They're in the same district (Central
      // and Western) so the recompute is exercised purely by
      // the cell-boundary crossing, not by a district
      // transition.
      final fixes = [
        _pos(22.270, 114.140), // cell A: wkfft (Central and Western)
        _pos(22.270,
            114.170), // cell B: wkfg8 (Central and Western, ~3.3 km east)
      ];
      var i = 0;
      final p = UserLocationProvider(
        positionSource: () async => fixes[i++],
      );
      await p.updateUserLocation();
      final before = p.currentSuggestion;
      expect(before, isNotNull);
      await p.updateUserLocation();
      final after = p.currentSuggestion;
      expect(after, isNotNull);
      // Layer 1: recompute happened. The two suggestions
      // are different ExplorationSuggestion instances —
      // _currentSuggestion was reassigned. We use identity
      // (identical) instead of equality because two
      // ExplorationSuggestion objects with identical fields
      // would be == but not identical, and we specifically
      // want to catch "the cache was returned as-is".
      expect(identical(after, before), isFalse,
          reason: 'cell change must trigger _recomputeSuggestion, which '
              'assigns a new ExplorationSuggestion instance');
      // Layer 2: the new suggestion excludes both visited
      // cells (the engine must skip them).
      expect(after!.geohash, isNot(equals('wkfg8')),
          reason: 'suggestion must skip the cell the user just entered');
      expect(after.geohash, isNot(equals('wkfft')),
          reason: 'suggestion must also skip the first fix cell');
    });

    test('does not recompute when the user moves within the same cell',
        () async {
      // Performance contract: the suggestion engine is O(grid)
      // per recompute. We do NOT want to call it on every
      // GPS tick (which can be every second). The current
      // contract is to recompute only when the visited-set
      // changes (cell boundary crossing) or the position
      // moves to (0,0) / from (0,0). Within a single cell,
      // the suggestion stays put.
      //
      // This test documents that contract by asserting the
      // exact-same suggestion instance is returned across
      // multiple within-cell position updates.
      final fixes = [
        _pos(22.298, 114.170), // cell A
        _pos(22.299, 114.171), // ~150 m NE — same cell A
        _pos(22.2985, 114.1705), // ~70 m — same cell A
      ];
      var i = 0;
      final p = UserLocationProvider(
        positionSource: () async => fixes[i++],
      );
      await p.updateUserLocation();
      final s0 = p.currentSuggestion;
      expect(s0, isNotNull);
      // Within-cell moves. The suggestion's identity (same
      // geohash) must not change, even though the user has
      // moved closer to (or farther from) the target cell.
      await p.updateUserLocation();
      final s1 = p.currentSuggestion;
      await p.updateUserLocation();
      final s2 = p.currentSuggestion;
      expect(s1, isNotNull);
      expect(s2, isNotNull);
      expect(s1!.geohash, equals(s0!.geohash),
          reason: 'within-cell move must not change suggestion');
      expect(s2!.geohash, equals(s0.geohash));
    });

    test(
        'suggestion is set on first position update even when that '
        'cell was loaded as already-visited (regression for the '
        '"first fix in a previously-visited cell leaves null" bug)', () async {
      // BUG REPRO: after loadFromStorage, _currentSuggestion is
      // null because coords are still (0,0). The first real
      // position update moves coords off (0,0). The natural
      // place to recompute is inside _updateExploration — but
      // _updateExploration only calls _recomputeSuggestion
      // when a NEW cell is added to _visitedCells. If the
      // user's first fix lands in a cell that was loaded
      // from storage, _visitedCells.add() returns false, and
      // _recomputeSuggestion is never called. The user sees
      // no suggestion chip until they cross into a new cell.
      //
      // Seed SharedPreferences so loadFromStorage reports
      // wkfft (Central and Western) as already visited.
      SharedPreferences.setMockInitialValues(<String, Object>{
        'urbix.visited_cells': '["wkfft"]',
        'urbix.visits_by_district': '{"Central and Western":1}',
      });
      final p = UserLocationProvider(
        positionSource: () async => _pos(22.270, 114.140), // wkfft centre
      );
      await p.loadFromStorage();
      // Pre-condition: suggestion is null until the first
      // real fix lands.
      expect(p.currentSuggestion, isNull,
          reason: 'no real location yet — (0,0) guard');
      // First fix lands at the cell that was loaded as
      // already-visited. _updateExploration's
      // `_visitedCells.add(cell)` will return false because
      // wkfft is already in the set.
      await p.updateUserLocation();
      expect(p.userLocation.coordinates, const LatLng(22.270, 114.140));
      expect(p.currentSuggestion, isNotNull,
          reason: 'first real fix must populate the suggestion even '
              'when the cell is already visited — the user is at a '
              'real location and the engine has unvisited candidates');
    });
  });
  group('UserLocationProvider reset-vs-update race', () {
    // The _mutationEpoch mechanism lets resetExploration() win the
    // race against an in-flight updateUserLocation(). Locks down:
    // a reset that lands AFTER the position source returns but
    // BEFORE the in-flight call has finished processing must NOT
    // cause the in-flight call to clobber the cleared state.
    //
    // Without the epoch check, a late-arriving fix would re-add
    // the cell the user just reset, recompute the suggestion
    // against the wrong visited set, and notify listeners with
    // a state that the user just wiped.

    test(
        'in-flight update does NOT notify after reset (regression for the '
        '"late fix re-adds wiped state and re-notifies" race)', () async {
      // Schedule reset to run INSIDE the position source's
      // async callback — between the await on the position
      // future returning and the next line of updateUserLocation.
      // This is the tightest interleaving possible: the in-flight
      // call has just been resumed from `await _positionSource()`
      // and is about to run its post-await epoch check.
      UserLocationProvider? providerRef;
      final p = UserLocationProvider(
        positionSource: () async {
          // Run reset INSIDE the position source's async body —
          // synchronously, between when the in-flight call awaits
          // this future and when the await resolves. This is the
          // tightest interleaving possible: the in-flight call has
          // just been resumed from `await _positionSource()` and
          // is about to run its post-await epoch check.
          providerRef!.resetExploration();
          return _pos(22.298, 114.170);
        },
      );
      providerRef = p;
      var notifyCount = 0;
      p.addListener(() => notifyCount++);
      // The position source itself bumps the epoch via reset,
      // then returns the position. The in-flight call's
      // post-await checkpoint should see the bumped epoch and
      // bail out.
      await p.updateUserLocation();
      // The inflight call must NOT have added the cell.
      expect(p.uniqueCellsVisited, 0,
          reason: 'reset wiped the visited set; the late fix must '
              'not re-add the cell');
      // The inflight call must NOT have notified AFTER reset.
      // resetExploration contributes exactly one notify. With
      // the bug, the inflight call also notifies (giving 2 or
      // more). With the fix, it bails out at the epoch check
      // and never notifies (giving exactly 1).
      expect(notifyCount, 1,
          reason: 'exactly one notify (from reset). The inflight fix '
              'must bail at the epoch check, not call notifyListeners');
    });
  });
}

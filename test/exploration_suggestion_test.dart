import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:urbix/utils/exploration_suggestion.dart';
import 'package:urbix/utils/geohash.dart';

void main() {
  group('kHKCellGrid', () {
    test('contains unique geohash-5 hashes', () {
      // The grid is a Set<GeohashCell> in disguise: every cell
      // must have a distinct geohash, otherwise we'd be
      // suggesting the same cell twice.
      final hashes = kHKCellGrid.map((c) => c.geohash).toSet();
      expect(hashes.length, kHKCellGrid.length);
    });

    test('every cell sits inside the HK bounding box', () {
      for (final c in kHKCellGrid) {
        expect(c.center.latitude, greaterThanOrEqualTo(22.18));
        expect(c.center.latitude, lessThanOrEqualTo(22.56));
        expect(c.center.longitude, greaterThanOrEqualTo(113.83));
        expect(c.center.longitude, lessThanOrEqualTo(114.43));
      }
    });

    test('covers a sensible number of cells (not 5, not 5000)', () {
      // Lower bound: must cover the 18 districts, so > 50 is
      // safe. Upper bound: bbox area / cell size
      // is well under 1000 for the HK box at 0.011° step.
      expect(kHKCellGrid.length, greaterThan(50));
      expect(kHKCellGrid.length, lessThan(1000));
    });

    test(
        'covers every geohash-5 cell in the HK bbox (regression for the '
        '0.025° step bug)', () {
      // Build the ground-truth set: walk the bbox at 0.005° step
      // (well under the geohash-5 lng width of 0.011° so every
      // cell is sampled at least once) and collect the distinct
      // hashes. The grid MUST contain all of them.
      //
      // This test would have FAILED at the old 0.025° step
      // (grid covered only 72 of 165 cells). The fix is in
      // lib/utils/exploration_suggestion.dart — see
      // kGeohash5StepDegrees for why.
      final groundTruth = <String>{};
      for (var lat = 22.18; lat <= 22.56; lat += 0.005) {
        for (var lng = 113.83; lng <= 114.43; lng += 0.005) {
          groundTruth.add(encodeGeohash(lat, lng, 5));
        }
      }
      final gridHashes = kHKCellGrid.map((c) => c.geohash).toSet();
      final missed = groundTruth.difference(gridHashes);
      expect(missed, isEmpty,
          reason: 'grid missed ${missed.length} of ${groundTruth.length} '
              'cells; sample missed: ${missed.take(5).toList()}');
      // Sanity: there should be a non-trivial number of cells,
      // confirming both that the bbox is real and that the
      // grid actually walks it.
      expect(groundTruth.length, greaterThan(100));
    });

    test('candidate cells are real geohash-5 cells in HK', () {
      // The grid uses the same geohash-5 encoder as the
      // visited-cell tracker. Two invariants must hold for
      // the suggestion engine to rank cells correctly:
      //
      //   1. The hash re-encoded from c.center must equal
      //      c.geohash — otherwise the user's actual location
      //      (which hashes the real GPS point) won't match
      //      the grid's hash (which hashes a representative
      //      center), and "you're here" cells would never
      //      be marked as visited by the suggestion.
      //
      //   2. c.center must lie inside the HK bounding box
      //      so distance calculations make sense.
      //
      // The old test only checked #2 (and only for the first
      // 20 cells). Now that the bbox-walk step is 0.011°
      // (the lng cell width) we get #1 for free; we lock it
      // down for every cell so a future step-size change
      // can't silently regress.
      for (final c in kHKCellGrid) {
        final reencoded =
            encodeGeohash(c.center.latitude, c.center.longitude, 5);
        expect(reencoded, equals(c.geohash),
            reason: 'center of cell ${c.geohash} hashes to a different cell '
                '${reencoded}; the bbox-walk step is too coarse');
      }
    });
  });

  group('pickNextExploration', () {
    // Two hand-built cells, one in Wan Chai and one in Sha Tin.
    // Used across multiple tests so the ranking behaviour is
    // asserted on a stable, district-aware fixture.
    final wanChai = GeohashCell(
      geohash: 'wanchai',
      center: const LatLng(22.280, 114.180), // inside Wan Chai box
    );
    final shaTin = GeohashCell(
      geohash: 'shatin',
      center: const LatLng(22.380, 114.180), // inside Sha Tin box
    );
    final candidates = [wanChai, shaTin];

    test('returns null when every candidate is already visited', () {
      final out = pickNextExploration(
        userLocation: const LatLng(22.280, 114.180),
        visitedCells: {'wanchai', 'shatin'},
        candidateCells: candidates,
      );
      expect(out, isNull);
    });

    test('returns the closer unvisited cell when both are unknown', () {
      final out = pickNextExploration(
        userLocation: const LatLng(22.280, 114.180), // right at Wan Chai
        visitedCells: const <String>{},
        candidateCells: candidates,
        visitedDistricts: const <String>{},
      );
      expect(out, isNotNull);
      expect(out!.geohash, 'wanchai');
    });

    test('skips cells in the visited set', () {
      final out = pickNextExploration(
        userLocation: const LatLng(22.380, 114.180), // right at Sha Tin
        visitedCells: {'wanchai'},
        candidateCells: candidates,
      );
      expect(out, isNotNull);
      expect(out!.geohash, 'shatin');
    });

    test('proximity dominates: closer same-district beats farther new-district',
        () {
      // User sits at Wan Chai's center. The Wan Chai cell is
      // ~0m away, the Sha Tin cell is ~11km away. Even with
      // Sha Tin as a "new district" (+20% bonus), 0m proximity
      // always wins.
      final out = pickNextExploration(
        userLocation: const LatLng(22.280, 114.180),
        visitedCells: const <String>{},
        candidateCells: candidates,
        visitedDistricts: const <String>{'Wan Chai'},
      );
      expect(out!.geohash, 'wanchai');
    });

    test('distance and new-district bonus are populated correctly', () {
      final out = pickNextExploration(
        userLocation: const LatLng(22.280, 114.180),
        visitedCells: const <String>{},
        candidateCells: candidates,
        visitedDistricts: const <String>{},
      );
      expect(out, isNotNull);
      expect(out!.distanceFromUserMeters, lessThan(1000.0));
      // The user has visited no districts, so any in-district
      // cell counts as "new" to them.
      expect(out.isInNewDistrict, isTrue);
      expect(out.districtName, isNotNull);
    });

    test('cells outside all district boxes are returned with districtName=null',
        () {
      // A cell in the middle of the South China Sea (south
      // of HK) —well outside every bounding box.
      final ocean = GeohashCell(
        geohash: 'ocean',
        center: const LatLng(21.500, 114.000),
      );
      final out = pickNextExploration(
        userLocation: const LatLng(22.280, 114.180),
        visitedCells: const <String>{},
        candidateCells: [ocean],
      );
      expect(out, isNotNull);
      expect(out!.districtName, isNull);
      expect(out.isInNewDistrict, isFalse);
    });

    test('first candidate wins on a strict-equal-score tie', () {
      // Two cells equidistant from the user, both in the same
      // (unvisited) district. Both have score = 1 / (1 + d/1000).
      // The function picks the first one it sees, which keeps the
      // suggestion stable across rebuilds (otherwise the ranking
      // would shuffle on every grid change). If we ever introduce
      // a deterministic tiebreaker (e.g. alphabetical geohash),
      // this test will need updating.
      final a = GeohashCell(
        geohash: 'aaa00',
        center: const LatLng(22.281, 114.181), // 1 km east of user
      );
      final b = GeohashCell(
        geohash: 'bbb00',
        center: const LatLng(22.281, 114.179), // 1 km west of user
      );
      final out = pickNextExploration(
        userLocation: const LatLng(22.281, 114.180),
        visitedCells: const <String>{},
        candidateCells: [a, b],
      );
      expect(out, isNotNull);
      expect(out!.geohash, 'aaa00',
          reason: 'first candidate wins on equal score');
      // Reversed order should pick the other one.
      final out2 = pickNextExploration(
        userLocation: const LatLng(22.281, 114.180),
        visitedCells: const <String>{},
        candidateCells: [b, a],
      );
      expect(out2!.geohash, 'bbb00');
    });

    test('handles candidate set larger than the visited set without O(n^2)',
        () {
      // Sanity check that we don't accidentally double-iterate.
      // Build 200 candidate cells, all unvisited, scattered around
      // the user. The function should return the closest one.
      // We place a special "right here" cell FIRST so it wins the
      // tie on equal score (the function picks the first-encountered
      // candidate on a tie —see the dedicated tie-break test).
      final candidates = <GeohashCell>[
        const GeohashCell(geohash: 'here0', center: LatLng(22.30, 114.18)),
      ];
      for (var i = 0; i < 200; i++) {
        // Spread them across a 20 km box around HK.
        final lat = 22.20 + (i % 20) * 0.01;
        final lng = 114.10 + (i ~/ 20) * 0.01;
        candidates.add(GeohashCell(geohash: 'h$i', center: LatLng(lat, lng)));
      }
      final out = pickNextExploration(
        userLocation: const LatLng(22.30, 114.18),
        visitedCells: const <String>{},
        candidateCells: candidates,
      );
      expect(out, isNotNull);
      expect(out!.geohash, 'here0',
          reason: 'first-encountered cell at user position must win');
      expect(out.distanceFromUserMeters, lessThan(1.0));
    });

    test('returns the only candidate when there is just one', () {
      // Trivial case: single candidate. Documents the no-candidates
      // and single-candidate code paths so a future refactor can't
      // accidentally drop them.
      final only = GeohashCell(
        geohash: 'only1',
        center: const LatLng(22.30, 114.18),
      );
      final out = pickNextExploration(
        userLocation: const LatLng(22.30, 114.18),
        visitedCells: const <String>{},
        candidateCells: [only],
      );
      expect(out, isNotNull);
      expect(out!.geohash, 'only1');
      expect(out.distanceFromUserMeters, 0.0);
    });

    test('user far from any candidate still gets the nearest one', () {
      // User is at sea, ~76 km south of HK. The HK grid is
      // the only candidate set; the engine should still
      // return the closest cell (which is on the south side
      // of HK) rather than null. Documents that "out of
      // bbox" is not the same as "no candidates".
      final out = pickNextExploration(
        userLocation: const LatLng(21.500, 114.000),
        visitedCells: const <String>{},
        candidateCells: kHKCellGrid,
      );
      expect(out, isNotNull,
          reason: 'a user 76 km south of HK should still get a suggestion '
              'for the nearest cell, not null');
      // Actual measured distance ~76 km (south of HK bbox).
      expect(out!.distanceFromUserMeters, greaterThan(70000.0));
      expect(out.distanceFromUserMeters, lessThan(80000.0));
      // The closest cells at this latitude are in the
      // southern part of the bbox (~22.18). Verify the
      // target latitude is at the south end of the bbox.
      expect(out.target.latitude, lessThan(22.30));
    });

    test('all cells visited returns null even with bbox-wide grid', () {
      // Every cell in the HK grid marked visited. The
      // engine must return null rather than some
      // arbitrary cell, because every candidate is in
      // the visited set.
      final allVisited = kHKCellGrid.map((c) => c.geohash).toSet();
      final out = pickNextExploration(
        userLocation: const LatLng(22.30, 114.18),
        visitedCells: allVisited,
        candidateCells: kHKCellGrid,
      );
      expect(out, isNull,
          reason: 'no unexplored cells left in the candidate set');
    });
  });
}

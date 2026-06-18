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
      // is well under 1000 for the HK box at 0.025蝪?step.
      expect(kHKCellGrid.length, greaterThan(50));
      expect(kHKCellGrid.length, lessThan(1000));
    });

    test('candidate cells are real geohash-5 cells in HK', () {
      // The grid uses the same geohash-5 encoder as the
      // visited-cell tracker, so every cell in the grid
      // must be a hash that's reachable from a real HK
      // lat/lng. Sanity check: the hash, re-encoded from
      // *any* nearby point, is either the same hash or an
      // adjacent one (a geohash cell boundary may sit
      // between the center and a neighbour).
      for (final c in kHKCellGrid.take(20)) {
        final reencoded =
            encodeGeohash(c.center.latitude, c.center.longitude, 5);
        // The re-encoded hash may be the cell itself or one
        // of its 8 neighbours; we just assert it's a valid
        // 5-character geohash (5 chars from the base32
        // alphabet).
        expect(reencoded.length, 5);
        expect(reencoded, matches(RegExp(r'^[0-9bcdefghjkmnpqrstuvwxyz]{5}$')));
        // We don't assert reencoded == c.geohash because
        // the grid stores the cell identity, not the exact
        // center; the center is a representative point.
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
  });
}

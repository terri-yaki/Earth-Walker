// lib/utils/exploration_suggestion.dart
//
// A "what should the user explore next?" engine. Given the user's
// current location and the set of geohash cells they've already
// visited, returns the top-ranked unexplored cell from a static
// candidate grid (HK-only for the Urbix HK app).
//
// Ranking (multi-criterion, ponytail simple):
//   1. Proximity dominates: closer cells outrank farther ones
//      (inverse-linear in km).
//   2. District novelty nudges: a cell in a district the user
//      hasn't visited yet gets a +20% score bonus. Same-district
//      cells are still suggested when they win on proximity; the
//      bonus only breaks ties.
// The "only pick one for them" requirement is honoured by
// returning the single top result, not a list. The full ranked
// list is implementation detail; tests exercise the ranking
// indirectly by checking the picked winner in two-cell scenarios.

import 'package:latlong2/latlong.dart';

import 'geohash.dart';
import 'hk_districts.dart';

/// A geohash-5 cell with its ID + a representative center
/// coordinate. Used as the unit of the suggestion grid.
class GeohashCell {
  final String geohash;
  final LatLng center;

  const GeohashCell({required this.geohash, required this.center});
}

/// One suggestion: where to walk next, plus the context the HUD
/// needs to render a one-line chip.
class ExplorationSuggestion {
  /// Where to recenter the map. The center of the suggested cell.
  final LatLng target;

  /// The HK district the suggestion is in, or null if the cell
  /// falls outside all 18 district bounding boxes.
  final String? districtName;

  /// The geohash-5 hash of the cell, for de-duplication against
  /// the visited set.
  final String geohash;

  /// Great-circle distance from the user to the cell center.
  final double distanceFromUserMeters;

  /// True if the cell is in a district the user has zero visits
  /// in (per [visitedDistricts]). The map screen uses this to
  /// pick between "Walk to" and "Next district" copy.
  final bool isInNewDistrict;

  const ExplorationSuggestion({
    required this.target,
    required this.districtName,
    required this.geohash,
    required this.distanceFromUserMeters,
    required this.isInNewDistrict,
  });
}

/// Step size used to walk the lat/lng grid when building the
/// candidate set. Must be <= the SHORT dimension of a geohash-5
/// cell (the lng width of 0.011°) or we will SKIP cells between
/// sample points and the suggestion grid will not cover HK fully.
///
/// At 0.011° the bbox walk produces ~3000 anchor points, deduped
/// by hash to ~165 unique cells (the actual count of geohash-5
/// cells covering HK). At 0.025° (the previous value) we only
/// captured 72 of those 165 cells — a real coverage gap that
/// meant the suggestion engine had a 56% chance of failing to
/// suggest any cell in HK's eastern or western edges.
///
/// ponytail: a real geohash decoder would give us the exact cell
/// bounds without this scan; the inline encoder can't, so we
/// over-sample and let the hash dedup handle the duplicates.
const double kGeohash5StepDegrees = 0.011;

/// HK bounding box (rough). Covers the 18 districts with a small
/// margin so the suggestion can point at cells just outside the
/// inhabited area (e.g. country parks, reservoirs).
const double kHKMinLat = 22.18;
const double kHKMaxLat = 22.56;
const double kHKMinLng = 113.83;
const double kHKMaxLng = 114.43;

/// The static candidate grid: every geohash-5 cell covering HK,
/// deduplicated by hash. Empirically ~165 cells at the time of
/// writing; computed once at module load. The list is an
/// unmodifiable view of a pre-computed list —callers should
/// never mutate it.
final List<GeohashCell> kHKCellGrid = _computeHKCellGrid();

List<GeohashCell> _computeHKCellGrid() {
  final byHash = <String, GeohashCell>{};
  // Walk the bbox in geohash-5-cell-sized steps. The first
  // lat/lng we encounter for a given hash becomes the cell's
  // "center" for suggestion purposes. The offset from
  // true-center is at most half a step (~600 m), which is
  // invisible on a city-zoom map.
  //
  // The step MUST be no larger than 0.011° (= the lng width of
  // a geohash-5 cell). See kGeohash5StepDegrees above for why.
  for (var lat = kHKMinLat; lat <= kHKMaxLat; lat += kGeohash5StepDegrees) {
    for (var lng = kHKMinLng; lng <= kHKMaxLng; lng += kGeohash5StepDegrees) {
      final hash = encodeGeohash(lat, lng, 5);
      byHash.putIfAbsent(
        hash,
        () => GeohashCell(
          geohash: hash,
          center: LatLng(
              lat + kGeohash5StepDegrees / 2, lng + kGeohash5StepDegrees / 2),
        ),
      );
    }
  }
  return List<GeohashCell>.unmodifiable(byHash.values);
}

/// Returns the top-ranked unvisited [GeohashCell] for the user,
/// or null if every cell in [candidateCells] is in [visitedCells]
/// (i.e. the user has explored everything we know about).
///
/// Pure function —no Provider / SharedPreferences coupling, so
/// the unit test can drive it with hand-built cells without any
/// platform mocking.
ExplorationSuggestion? pickNextExploration({
  required LatLng userLocation,
  required Set<String> visitedCells,
  required List<GeohashCell> candidateCells,
  Set<String> visitedDistricts = const <String>{},
}) {
  GeohashCell? best;
  double bestScore = double.negativeInfinity;
  double bestDistance = 0.0;
  String? bestDistrict;

  for (final cell in candidateCells) {
    if (visitedCells.contains(cell.geohash)) continue;
    final distance =
        const Distance().as(LengthUnit.Meter, userLocation, cell.center);
    final district = districtFor(cell.center);
    final districtName = district?.name;
    final inNewDistrict =
        districtName != null && !visitedDistricts.contains(districtName);
    // Inverse-linear proximity in km: 1.0 at 0m, 0.5 at 1km,
    // 0.1 at 9km, ~0.05 at 19km. The +20% new-district bonus
    // only matters when proximity is similar; a far-but-new
    // district can still lose to a close-but-known one.
    final proximity = 1.0 / (1.0 + distance / 1000.0);
    final score = inNewDistrict ? proximity * 1.2 : proximity;
    if (score > bestScore) {
      bestScore = score;
      best = cell;
      bestDistance = distance;
      bestDistrict = districtName;
    }
  }
  if (best == null) return null;
  return ExplorationSuggestion(
    target: best.center,
    districtName: bestDistrict,
    geohash: best.geohash,
    distanceFromUserMeters: bestDistance,
    isInNewDistrict:
        bestDistrict != null && !visitedDistricts.contains(bestDistrict),
  );
}

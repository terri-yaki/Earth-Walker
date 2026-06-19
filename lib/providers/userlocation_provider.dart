// lib/providers/userlocation_provider.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_location.dart';
import '../utils/district_counts.dart';
import '../utils/double_map.dart';
import '../utils/exploration_days.dart';
import '../utils/exploration_suggestion.dart';
import '../utils/geohash.dart';
import '../utils/hk_districts.dart';
import '../utils/lat_lng_list.dart';
import '../utils/visited_cells_store.dart';

/// Typed exception thrown by [_geolocatorPositionSource] when the
/// user has not granted location permission. Distinguished from
/// a generic [Exception] so the onboarding screen can map it to
/// a localised user-facing message instead of leaking the
/// hardcoded English string into the zh-HK UI.
class LocationPermissionDeniedException implements Exception {
  const LocationPermissionDeniedException();
}

/// Default [UserLocationProvider] position source: the Geolocator
/// permission check + getCurrentPosition flow. Pulled out as a
/// top-level function so the production behaviour is unchanged
/// after the position-source refactor, and so tests can inject
/// a stub via the constructor without touching Geolocator.
Future<Position> _geolocatorPositionSource() async {
  // Check location permissions
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    permission = await Geolocator.requestPermission();
    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      throw const LocationPermissionDeniedException();
    }
  }
  return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
}

/// A Provider that manages the user's location, map auto-centering,
/// zoom level, and exploration percentages.
class UserLocationProvider with ChangeNotifier {
  /// The user's current location.
  UserLocation _userLocation;

  /// Determines whether the map should auto-center on the user's location.
  bool _isRecentered;

  /// The current zoom level of the map.
  double _currentZoom;

  /// Percentage of the country explored.
  int _countryPercentage;

  /// Percentage of the continent explored.
  int _continentPercentage;

  /// Percentage of the world explored.
  int _worldPercentage;

  /// Cumulative walking distance in meters, accumulated across all
  /// successful geolocator updates since the last reset / app start.
  double _totalDistanceMeters = 0.0;

  /// Last location used for distance accumulation, so we can compute
  /// the step from "previous" to "current". Null until the first
  /// successful fix, or after a reset.
  LatLng? _lastDistanceReference;

  /// Single-update step beyond this is treated as GPS noise and ignored.
  /// 3.0 km covers fast cycling / driving between two slow updates and
  /// also covers crossing several adjacent geohash-5 cells (each is
  /// ~1.2 km wide at HK latitude — see lib/utils/geohash.dart for the
  /// size table); anything bigger is almost certainly a cold-start fix
  /// or a sensor glitch, not real movement.
  /// ponytail: was 1500 m, but that rejected legitimate cross-cell
  /// walks (geohash-5 is ~1.2 km wide here, ~20 km tall) and made the
  /// unique-cell counter look broken to users.
  static const double kMaxPlausibleStepMeters = 3000.0;

  /// Function that returns the device's current position. The default
  /// wraps the Geolocator permission + getCurrentPosition flow; tests
  /// inject a stub that returns a fixed [Position] so the full
  /// update cycle (distance accumulation, exploration tracking,
  /// per-district bump) can be exercised without GPS hardware or
  /// permission mocks.
  final Future<Position> Function() _positionSource;

  /// Monotonic counter bumped by [resetExploration]. An in-flight
  /// [updateUserLocation] captures the value at entry and bails out
  /// at the post-await checkpoints if the counter has advanced —
  /// so a reset that lands mid-update doesn't get clobbered by a
  /// late-arriving location fix. Closes AUDIT.md A2.
  int _mutationEpoch = 0;

  /// Constructor to initialize the provider with default values.
  UserLocationProvider({
    UserLocation? initialLocation,
    bool isRecentered = true,
    double currentZoom = 18.0, // Set to maximum zoom level for street view
    int countryPercentage = 0,
    int continentPercentage = 0,
    int worldPercentage = 0,
    double totalDistanceMeters = 0.0,
    LatLng? lastDistanceReference,
    Future<Position> Function()? positionSource,
  })  : _userLocation = initialLocation ??
            UserLocation(coordinates: LatLng(0.0, 0.0)), // Default to (0,0)
        _isRecentered = isRecentered,
        _currentZoom = currentZoom,
        _countryPercentage = countryPercentage,
        _continentPercentage = continentPercentage,
        _worldPercentage = worldPercentage,
        _totalDistanceMeters = totalDistanceMeters,
        _lastDistanceReference = lastDistanceReference,
        _positionSource = positionSource ?? _geolocatorPositionSource;

  /// Getter for the user's current location.
  UserLocation get userLocation => _userLocation;

  /// Getter for the auto-centering flag.
  bool get isRecentered => _isRecentered;

  /// Getter for the current zoom level.
  double get currentZoom => _currentZoom;

  /// Getter for the country exploration percentage.
  int get countryPercentage => _countryPercentage;

  /// Getter for the continent exploration percentage.
  int get continentPercentage => _continentPercentage;

  /// Getter for the world exploration percentage.
  int get worldPercentage => _worldPercentage;

  /// Cumulative walking distance in meters since the last reset.
  double get totalDistanceMeters => _totalDistanceMeters;

  /// The HK district the user is currently in, or null if their
  /// current location is outside the 18-district bounding boxes
  /// (e.g. they're at sea, or their location hasn't been fetched).
  String? get currentDistrictName {
    final coords = _userLocation.coordinates;
    // Skip the (0,0) default —that's "location not set yet", not
    // a real reading from the South Atlantic.
    if (coords.latitude == 0.0 && coords.longitude == 0.0) return null;
    return districtFor(coords)?.name;
  }

  /// Updates the user's location by fetching the current position.
  ///
  /// Uses the injected [_positionSource] to obtain a [Position].
  /// In production this defaults to [_geolocatorPositionSource],
  /// which checks permission then calls Geolocator.getCurrentPosition.
  /// Tests inject a stub.
  ///
  /// [resetExploration] may run while this is awaiting. We capture
  /// the [_mutationEpoch] at entry; if it advances (because a
  /// reset happened), we bail out instead of clobbering the reset
  /// with late-arriving state. See AUDIT.md A2.
  Future<void> updateUserLocation() async {
    final epochAtStart = _mutationEpoch;
    try {
      // Get the current position via the (possibly injected) source.
      final Position position = await _positionSource();
      if (_mutationEpoch != epochAtStart) return; // a reset won the race

      // Capture the previous coordinates BEFORE updating, so we
      // can detect the (0,0) -> real-location transition below.
      // The (0,0) default in the constructor means "no real
      // location yet" (see [currentDistrictName] and the guard
      // in [_recomputeSuggestion]); once we have a real fix,
      // _recomputeSuggestion must run at least once even if
      // _updateExploration is a no-op (cell already visited).
      final wasAtDefault = _userLocation.coordinates.latitude == 0.0 &&
          _userLocation.coordinates.longitude == 0.0;

      // Update the user's location
      _userLocation = UserLocation(
          coordinates: LatLng(position.latitude, position.longitude));

      // Accumulate walking distance since the previous fix. We skip
      // absurdly large jumps (single-update distances above
      // [kMaxPlausibleStepMeters]) to filter out GPS noise / cold-start
      // swings. ponytail: this is a coarse filter —a future
      // implementation should use a Kalman filter or velocity-scaled
      // outlier rejection.
      _accumulateDistance(_userLocation.coordinates);
      if (_mutationEpoch != epochAtStart) return; // belt and braces

      // Update exploration percentages
      _updateExploration(_userLocation.coordinates);

      // Seed the suggestion on the first transition off (0,0).
      // _updateExploration only calls _recomputeSuggestion when
      // a new cell is added —so if the user's first fix lands in
      // a cell that was already in _visitedCells (e.g. loaded from
      // a previous session), _recomputeSuggestion is never called
      // and the suggestion chip stays null until they cross into
      // a new cell. Force a recompute here to close that gap.
      // After this first fix, within-cell moves still skip the
      // recompute (the "does not recompute when the user moves
      // within the same cell" performance contract).
      if (wasAtDefault) _recomputeSuggestion();

      // Notify listeners about the update
      notifyListeners();
    } catch (e) {
      // Handle any errors
      debugPrint('Error updating user location: $e');
      throw e;
    }
  }

  /// Toggles the auto-centering behavior of the map.
  ///
  /// When set to `false`, the map will not auto-center on the user's location
  /// even if the user's location changes. When set to `true`, the map will
  /// auto-center as long as the user's location updates.
  void setRecentered(bool value) {
    _isRecentered = value;
    notifyListeners();
  }

  /// Updates the current zoom level of the map.
  ///
  /// This method can be called when the user zooms in or out of the map.
  void updateZoom(double newZoom) {
    _currentZoom = newZoom;
    notifyListeners();
  }

  /// Geohash precision used for visited-cell tracking. Precision 5
  /// gives cells of about 20 km tall × 1.2 km wide at HK latitude
  /// (see lib/utils/geohash.dart for the full table). That's a good
  /// size for "you walked somewhere new" — east-west movement of
  /// ~600 m is enough to trigger a new cell, while a single 20 km
  /// north-south walk stays in the same cell (which is the right
  /// behaviour: a stroll along the harbour shouldn't rack up 10
  /// "new places" badges).
  static const int _geohashPrecision = 5;

  /// SharedPreferences key for the visited-cell set.
  static const String _prefsKeyVisitedCells = 'urbix.visited_cells';

  /// SharedPreferences key for the cumulative walking distance in meters.
  static const String _prefsKeyTotalDistance = 'urbix.total_distance_meters';

  /// SharedPreferences key for the set of yyyy-mm-dd exploration day keys.
  static const String _prefsKeyExplorationDays = 'urbix.exploration_days';

  /// SharedPreferences key for the per-district visit count map
  /// (district name -> unique cells visited in that district).
  static const String _prefsKeyVisitsByDistrict = 'urbix.visits_by_district';

  /// SharedPreferences key for the per-day distance map
  /// (yyyy-mm-dd -> meters walked that day).
  static const String _prefsKeyDistanceByDay = 'urbix.distance_by_day';

  /// SharedPreferences key for the visited-cell locations (parallel
  /// to the visited-cell set; needed so the green-dot footprint
  /// overlay survives an app restart, not just the cell count).
  static const String _prefsKeyVisitedCellLocations =
      'urbix.visited_cell_locations';

  /// Set of geohash cells the user has already visited.
  /// Tracked so revisiting the same cell doesn't inflate the count.
  /// Backed by SharedPreferences on disk; see [loadFromStorage] / [saveToStorage].
  final Set<String> _visitedCells = <String>{};

  /// Representative LatLng for each visited cell, used to render the
  /// "footprint" overlay on the map. Persisted to SharedPreferences
  /// under [_prefsKeyVisitedCellLocations] so the green dots
  /// survive an app restart.
  final List<LatLng> _visitedCellLocations = <LatLng>[];

  /// Set of yyyy-mm-dd day keys on which the user has recorded at
  /// least one new cell. Persisted to SharedPreferences.
  final Set<String> _explorationDays = <String>{};

  /// Number of unique cells visited in each HK district. Persisted.
  /// Bumped in [_updateExploration] when a new cell falls inside a
  /// known district box. Read-only externally.
  final Map<String, int> _visitsByDistrict = <String, int>{};

  /// Meters walked per local-time day (yyyy-mm-dd -> meters).
  /// Bumped in [_accumulateDistance] alongside [_totalDistanceMeters].
  /// Persisted to SharedPreferences.
  final Map<String, double> _distanceByDay = <String, double>{};

  /// The current top-ranked suggestion for where to explore next.
  /// Recomputed in [_recomputeSuggestion] whenever the user's
  /// location changes, the visited-cell set changes, or a reset
  /// clears it. Null if the user has no real location yet (still
  /// at the (0,0) default) or has explored every cell we know
  /// about. Read by the map HUD to render the "Next" chip.
  ExplorationSuggestion? _currentSuggestion;

  /// The top-ranked unexplored cell for the user, or null if
  /// there's nothing left to suggest. See [_currentSuggestion].
  ExplorationSuggestion? get currentSuggestion => _currentSuggestion;

  /// Number of distinct cells the user has entered (read-only).
  int get uniqueCellsVisited => _visitedCells.length;

  /// Distance in meters walked today (local-time). 0 if the user
  /// hasn't moved yet today. Used by the HUD's 'Today' line.
  double get todayDistanceMeters {
    final key = dayKey(DateTime.now());
    return _distanceByDay[key] ?? 0.0;
  }

  /// Number of distinct calendar days the user has explored on.
  int get daysExplored => _explorationDays.length;

  /// Number of consecutive days, ending today (or yesterday if the
  /// user hasn't moved yet today), on which the user has recorded at
  /// least one new cell. 0 if the most recent exploration day is
  /// older than yesterday. Used by the HUD's streak chip.
  int get currentStreakDays {
    DateTime cursor = DateTime.now();
    int streak = 0;
    // Allow up to one day of grace: if the user walked yesterday but
    // not yet today, the streak is still alive.
    if (!_explorationDays.contains(dayKey(cursor))) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!_explorationDays.contains(dayKey(cursor))) {
        return 0;
      }
    }
    while (_explorationDays.contains(dayKey(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Per-district unique-cell counts. Returns an unmodifiable view.
  Map<String, int> get visitsByDistrict => Map.unmodifiable(_visitsByDistrict);

  /// Number of unique cells the user has recorded in their current
  /// district (or 0 if they're not in a known district).
  int get cellsInCurrentDistrict {
    final name = currentDistrictName;
    if (name == null) return 0;
    return _visitsByDistrict[name] ?? 0;
  }

  /// One LatLng per visited cell, in visit order. Used by the map view
  /// to render the green exploration dots.
  List<LatLng> get visitedCellLocations =>
      List.unmodifiable(_visitedCellLocations);

  /// Restore the visited-cell set, cumulative distance, exploration-day
  /// set, and per-district visit counts from SharedPreferences. Call once
  /// at app startup (e.g. from MapScreen.initState) so progress survives
  /// restarts. Silently no-ops on any storage error.
  Future<void> loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _visitedCells
        ..clear()
        ..addAll(cellsFromJson(prefs.getString(_prefsKeyVisitedCells)));
      _totalDistanceMeters = prefs.getDouble(_prefsKeyTotalDistance) ?? 0.0;
      _explorationDays
        ..clear()
        ..addAll(cellsFromJson(prefs.getString(_prefsKeyExplorationDays)));
      _visitsByDistrict
        ..clear()
        ..addAll(districtCountMapFromJson(
            prefs.getString(_prefsKeyVisitsByDistrict)));
      _distanceByDay
        ..clear()
        ..addAll(doubleMapFromJson(prefs.getString(_prefsKeyDistanceByDay)));
      _visitedCellLocations
        ..clear()
        ..addAll(
            latLngListFromJson(prefs.getString(_prefsKeyVisitedCellLocations)));
      _lastDistanceReference = null; // first new fix will set it
      _recalculatePercentages();
      // Seed the suggestion from the loaded state. The user's
      // location is still (0,0) at this point, so this will
      // resolve to null; the real suggestion comes after the
      // first updateUserLocation fix. Calling it here keeps
      // the state shape consistent for any listener that
      // inspects the suggestion before the first GPS fix.
      _recomputeSuggestion();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load visited cells: $e');
    }
  }

  /// Persist the current visited-cell set, cumulative distance,
  /// exploration-day set, and per-district visit counts to
  /// SharedPreferences. Called automatically whenever a new cell is
  /// recorded or the distance counter advances; can also be called
  /// explicitly (e.g. on app pause) to guarantee a flush.
  Future<void> saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKeyVisitedCells, cellsToJson(_visitedCells));
      await prefs.setDouble(_prefsKeyTotalDistance, _totalDistanceMeters);
      await prefs.setString(
          _prefsKeyExplorationDays, cellsToJson(_explorationDays));
      await prefs.setString(
          _prefsKeyVisitsByDistrict, districtCountMapToJson(_visitsByDistrict));
      await prefs.setString(
          _prefsKeyDistanceByDay, doubleMapToJson(_distanceByDay));
      await prefs.setString(_prefsKeyVisitedCellLocations,
          latLngListToJson(_visitedCellLocations));
    } catch (e) {
      debugPrint('Failed to save visited cells: $e');
    }
  }

  /// Add the great-circle distance from the previous reference location
  /// to [current] onto the running total. First fix after a reset has
  /// no previous reference, so the counter starts at 0. Single-step
  /// jumps above [kMaxPlausibleStepMeters] are dropped as GPS noise.
  void _accumulateDistance(LatLng current) {
    final prev = _lastDistanceReference;
    if (prev != null) {
      final step = const Distance().as(LengthUnit.Meter, prev, current);
      if (step > 0 && step <= kMaxPlausibleStepMeters) {
        _totalDistanceMeters += step;
        // Also bump today's bucket so the HUD's 'Today' line tracks
        // the same step. Keyed by local-time dayKey so the boundary
        // crosses at the user's midnight, not UTC.
        final today = dayKey(DateTime.now());
        _distanceByDay.update(today, (v) => v + step, ifAbsent: () => step);
        // Save on every increment; the value is a single double so this
        // is cheap and keeps the persisted total in sync with the HUD.
        saveToStorage();
      }
    }
    _lastDistanceReference = current;
  }

  /// Updates exploration percentages based on the user's location.
  ///
  /// Real implementation: encode the location to a geohash cell and track
  /// the set of cells visited. Each new cell counts as 1% of the world,
  /// capped at 100%. Re-visiting the same cell is a no-op.
  ///
  /// ponytail: the "1 cell = 1% world" scaling is intentionally generous so
  /// the prototype feels responsive. A real implementation would divide by
  /// a more honest denominator (e.g. total cells covering land) —easy
  /// upgrade later, no architectural change required.
  void _updateExploration(LatLng location) {
    final cell =
        encodeGeohash(location.latitude, location.longitude, _geohashPrecision);
    if (_visitedCells.add(cell)) {
      _visitedCellLocations.add(location);
      _explorationDays.add(dayKey(DateTime.now()));
      // Per-district bump: a cell inside a known HK district box
      // increments that district's count. Cells outside HK stay out
      // of the map, which is correct —we only have district boxes
      // for Hong Kong.
      // Bump the per-district count BEFORE recomputing the
      // suggestion, so the suggestion engine sees the new
      // district in its visitedDistricts set on the same call
      // (otherwise a fresh-district cell would not get the
      // +20% "new district" bonus until the NEXT position
      // update recomputes).
      final district = districtFor(location);
      if (district != null) {
        _visitsByDistrict.update(
          district.name,
          (v) => v + 1,
          ifAbsent: () => 1,
        );
      }
      // The visited set may have just changed; recompute the
      // suggestion so the HUD's "Next" chip points at the best
      // new target.
      _recomputeSuggestion();
      _recalculatePercentages();
      // Fire-and-forget save; failure is non-fatal.
      saveToStorage();
    }
  }

  /// Recompute the three exploration percentages from [_visitedCells.length].
  /// Called after loading from storage and after each new cell.
  void _recalculatePercentages() {
    final next = _visitedCells.length.clamp(0, 100);
    _countryPercentage = next;
    _continentPercentage = next;
    _worldPercentage = next;
  }

  /// Resets all exploration percentages to zero, clears visited cells,
  /// Resets all exploration percentages to zero, clears visited cells,
  /// and zeros the cumulative distance, days-explored, and
  /// per-district counters. Bumps [_mutationEpoch] so any in-flight
  /// [updateUserLocation] bails out at its next checkpoint instead
  /// of clobbering the reset.
  void resetExploration() {
    _countryPercentage = 0;
    _continentPercentage = 0;
    _worldPercentage = 0;
    _visitedCells.clear();
    _visitedCellLocations.clear();
    _totalDistanceMeters = 0.0;
    _lastDistanceReference = null;
    _explorationDays.clear();
    _visitsByDistrict.clear();
    _distanceByDay.clear();
    _mutationEpoch++;
    // Reset re-opens the entire HK cell grid to "unvisited",
    // so the suggestion must be recomputed; otherwise the chip
    // would keep pointing at a cell the user has now reset.
    _recomputeSuggestion();
    saveToStorage();
    notifyListeners();
  }

  /// Recompute [_currentSuggestion] from the current location,
  /// visited-cell set, and per-district visit counts. Called
  /// after every state change that affects any of those inputs.
  /// Cheap (O(grid) where grid ~300 cells), so we don't bother
  /// memoising.
  void _recomputeSuggestion() {
    final coords = _userLocation.coordinates;
    // Same guard as [currentDistrictName]: (0,0) means "no
    // real location yet", and suggesting "explore a cell 13,000
    // km away" is unhelpful.
    if (coords.latitude == 0.0 && coords.longitude == 0.0) {
      _currentSuggestion = null;
      return;
    }
    _currentSuggestion = pickNextExploration(
      userLocation: coords,
      visitedCells: _visitedCells,
      candidateCells: kHKCellGrid,
      visitedDistricts: _visitsByDistrict.keys.toSet(),
    );
  }
}

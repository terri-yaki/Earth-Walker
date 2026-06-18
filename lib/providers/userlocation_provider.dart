// lib/providers/userlocation_provider.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_location.dart';
import '../utils/district_counts.dart';
import '../utils/exploration_days.dart';
import '../utils/geohash.dart';
import '../utils/hk_districts.dart';
import '../utils/visited_cells_store.dart';

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
      throw Exception('Location permissions are denied');
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
  /// 1.5 km covers fast cycling / driving between two slow updates;
  /// anything bigger is almost certainly a cold-start fix or a sensor
  /// glitch, not real movement.
  static const double kMaxPlausibleStepMeters = 1500.0;

  /// Function that returns the device's current position. The default
  /// wraps the Geolocator permission + getCurrentPosition flow; tests
  /// inject a stub that returns a fixed [Position] so the full
  /// update cycle (distance accumulation, exploration tracking,
  /// per-district bump) can be exercised without GPS hardware or
  /// permission mocks.
  final Future<Position> Function() _positionSource;

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
    // Skip the (0,0) default — that's "location not set yet", not
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
  Future<void> updateUserLocation() async {
    try {
      // Get the current position via the (possibly injected) source.
      final Position position = await _positionSource();

      // Update the user's location
      _userLocation =
          UserLocation(coordinates: LatLng(position.latitude, position.longitude));

      // Accumulate walking distance since the previous fix. We skip
      // absurdly large jumps (single-update distances above
      // [kMaxPlausibleStepMeters]) to filter out GPS noise / cold-start
      // swings. ponytail: this is a coarse filter — a future
      // implementation should use a Kalman filter or velocity-scaled
      // outlier rejection.
      _accumulateDistance(_userLocation.coordinates);

      // Update exploration percentages
      _updateExploration(_userLocation.coordinates);

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

  /// Geohash precision used for visited-cell tracking. Precision 5 is about
  /// a 2.4 km × 2.4 km cell at the equator — a good size for "you walked
  /// somewhere new" without inflating the count from GPS noise.
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

  /// Set of geohash cells the user has already visited.
  /// Tracked so revisiting the same cell doesn't inflate the count.
  /// Backed by SharedPreferences on disk; see [loadFromStorage] / [saveToStorage].
  final Set<String> _visitedCells = <String>{};

  /// Representative LatLng for each visited cell, used to render the
  /// "footprint" overlay on the map. In-memory only — on app restart we
  /// only have the geohash cells back, so the footprint will repopulate
  /// as the user re-enters previously-visited cells. Cheap to keep.
  final List<LatLng> _visitedCellLocations = <LatLng>[];

  /// Set of yyyy-mm-dd day keys on which the user has recorded at
  /// least one new cell. Persisted to SharedPreferences.
  final Set<String> _explorationDays = <String>{};

  /// Number of unique cells visited in each HK district. Persisted.
  /// Bumped in [_updateExploration] when a new cell falls inside a
  /// known district box. Read-only externally.
  final Map<String, int> _visitsByDistrict = <String, int>{};

  /// Number of distinct cells the user has entered (read-only).
  int get uniqueCellsVisited => _visitedCells.length;

  /// Number of distinct calendar days the user has explored on.
  int get daysExplored => _explorationDays.length;

  /// Per-district unique-cell counts. Returns an unmodifiable view.
  Map<String, int> get visitsByDistrict =>
      Map.unmodifiable(_visitsByDistrict);

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
      _lastDistanceReference = null; // first new fix will set it
      _recalculatePercentages();
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
      await prefs.setString(_prefsKeyVisitsByDistrict,
          districtCountMapToJson(_visitsByDistrict));
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
  /// a more honest denominator (e.g. total cells covering land) — easy
  /// upgrade later, no architectural change required.
  void _updateExploration(LatLng location) {
    final cell = encodeGeohash(location.latitude, location.longitude, _geohashPrecision);
    if (_visitedCells.add(cell)) {
      _visitedCellLocations.add(location);
      _explorationDays.add(dayKey(DateTime.now()));
      // Per-district bump: a cell inside a known HK district box
      // increments that district's count. Cells outside HK stay out
      // of the map, which is correct — we only have district boxes
      // for Hong Kong.
      final district = districtFor(location);
      if (district != null) {
        _visitsByDistrict.update(
          district.name,
          (v) => v + 1,
          ifAbsent: () => 1,
        );
      }
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
  /// and zeros the cumulative distance, days-explored, and
  /// per-district counters.
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
    saveToStorage();
    notifyListeners();
  }
}

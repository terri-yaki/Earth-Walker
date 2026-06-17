// lib/providers/userlocation_provider.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_location.dart';
import '../utils/geohash.dart';
import '../utils/visited_cells_store.dart';

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
  })  : _userLocation = initialLocation ??
                UserLocation(coordinates: LatLng(0.0, 0.0)), // Default to (0,0)
        _isRecentered = isRecentered,
        _currentZoom = currentZoom,
        _countryPercentage = countryPercentage,
        _continentPercentage = continentPercentage,
        _worldPercentage = worldPercentage,
        _totalDistanceMeters = totalDistanceMeters,
        _lastDistanceReference = lastDistanceReference;

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

  /// Updates the user's location by fetching the current position.
  ///
  /// This method fetches the user's current location, updates the
  /// exploration percentages, and notifies listeners.
  Future<void> updateUserLocation() async {
    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          // Permissions are denied, handle appropriately
          throw Exception('Location permissions are denied');
        }
      }

      // Get the current position
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

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

  /// Set of geohash cells the user has already visited.
  /// Tracked so revisiting the same cell doesn't inflate the count.
  /// Backed by SharedPreferences on disk; see [loadFromStorage] / [saveToStorage].
  final Set<String> _visitedCells = <String>{};

  /// Representative LatLng for each visited cell, used to render the
  /// "footprint" overlay on the map. In-memory only — on app restart we
  /// only have the geohash cells back, so the footprint will repopulate
  /// as the user re-enters previously-visited cells. Cheap to keep.
  final List<LatLng> _visitedCellLocations = <LatLng>[];

  /// Number of distinct cells the user has entered (read-only).
  int get uniqueCellsVisited => _visitedCells.length;

  /// One LatLng per visited cell, in visit order. Used by the map view
  /// to render the green exploration dots.
  List<LatLng> get visitedCellLocations =>
      List.unmodifiable(_visitedCellLocations);

  /// Restore the visited-cell set and cumulative distance from
  /// SharedPreferences. Call once at app startup (e.g. from
  /// MapScreen.initState) so progress survives restarts. Silently
  /// no-ops on any storage error.
  Future<void> loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _visitedCells
        ..clear()
        ..addAll(cellsFromJson(prefs.getString(_prefsKeyVisitedCells)));
      _totalDistanceMeters = prefs.getDouble(_prefsKeyTotalDistance) ?? 0.0;
      _lastDistanceReference = null; // first new fix will set it
      _recalculatePercentages();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load visited cells: $e');
    }
  }

  /// Persist the current visited-cell set and cumulative distance to
  /// SharedPreferences. Called automatically whenever a new cell is
  /// recorded or the distance counter advances; can also be called
  /// explicitly (e.g. on app pause) to guarantee a flush.
  Future<void> saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKeyVisitedCells, cellsToJson(_visitedCells));
      await prefs.setDouble(_prefsKeyTotalDistance, _totalDistanceMeters);
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
  /// and zeros the cumulative distance counter.
  void resetExploration() {
    _countryPercentage = 0;
    _continentPercentage = 0;
    _worldPercentage = 0;
    _visitedCells.clear();
    _visitedCellLocations.clear();
    _totalDistanceMeters = 0.0;
    _lastDistanceReference = null;
    saveToStorage();
    notifyListeners();
  }
}

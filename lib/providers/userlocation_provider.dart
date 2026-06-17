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

  /// Constructor to initialize the provider with default values.
  UserLocationProvider({
    UserLocation? initialLocation,
    bool isRecentered = true,
    double currentZoom = 18.0, // Set to maximum zoom level for street view
    int countryPercentage = 0,
    int continentPercentage = 0,
    int worldPercentage = 0,
  })  : _userLocation = initialLocation ??
                UserLocation(coordinates: LatLng(0.0, 0.0)), // Default to (0,0)
        _isRecentered = isRecentered,
        _currentZoom = currentZoom,
        _countryPercentage = countryPercentage,
        _continentPercentage = continentPercentage,
        _worldPercentage = worldPercentage;

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

      // Optionally, update exploration percentages
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

  /// Set of geohash cells the user has already visited.
  /// Tracked so revisiting the same cell doesn't inflate the count.
  /// Backed by SharedPreferences on disk; see [loadFromStorage] / [saveToStorage].
  final Set<String> _visitedCells = <String>{};

  /// Number of distinct cells the user has entered (read-only).
  int get uniqueCellsVisited => _visitedCells.length;

  /// Restore the visited-cell set from SharedPreferences. Call once at
  /// app startup (e.g. from MapScreen.initState) so progress survives
  /// restarts. Silently no-ops on any storage error.
  Future<void> loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _visitedCells
        ..clear()
        ..addAll(cellsFromJson(prefs.getString(_prefsKeyVisitedCells)));
      _recalculatePercentages();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load visited cells: $e');
    }
  }

  /// Persist the current visited-cell set to SharedPreferences. Called
  /// automatically whenever a new cell is recorded; can also be called
  /// explicitly (e.g. on app pause) to guarantee a flush.
  Future<void> saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKeyVisitedCells, cellsToJson(_visitedCells));
    } catch (e) {
      debugPrint('Failed to save visited cells: $e');
    }
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

  /// Resets all exploration percentages to zero and clears visited cells.
  void resetExploration() {
    _countryPercentage = 0;
    _continentPercentage = 0;
    _worldPercentage = 0;
    _visitedCells.clear();
    saveToStorage();
    notifyListeners();
  }
}

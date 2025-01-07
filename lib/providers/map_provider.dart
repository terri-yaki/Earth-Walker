// lib/providers/map_provider.dart

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Manages map-related state such as user location, zoom level,
/// and real-time updates like fog of war or offline map toggles.
class MapProvider with ChangeNotifier {
  // User’s current location on the map
  LatLng _userLocation = LatLng(0, 0);

  // Flags for map behavior
  bool _isRecentered = true;
  double _currentZoom = 40.0;

  /// Exploration percentages
  int _countryPercentage = 0;
  int _continentPercentage = 0;
  int _worldPercentage = 0;

  // Getters
  LatLng get userLocation => _userLocation;
  bool get isRecentered => _isRecentered;
  double get currentZoom => _currentZoom;
  int get countryPercentage => _countryPercentage;
  int get continentPercentage => _continentPercentage;
  int get worldPercentage => _worldPercentage;

  /// Update user’s location
  void updateUserLocation(LatLng newLocation) {
    _userLocation = newLocation;
    _updateExploration(newLocation);
    notifyListeners();
  }

  /// Toggle map recentering
  void setRecentered(bool value) {
    _isRecentered = value;
    notifyListeners();
  }

  /// Update zoom level
  void updateZoom(double newZoom) {
    _currentZoom = newZoom;
    notifyListeners();
  }

  /// Update exploration percentages based on new location
  void _updateExploration(LatLng location) {
    // TODO: Implement real logic to calculate exploration based on location
    // For demonstration
    _countryPercentage += 1;
    _continentPercentage += 1;
    _worldPercentage += 1;

    // Cap percentages at 100%
    if (_countryPercentage > 100) _countryPercentage = 100;
    if (_continentPercentage > 100) _continentPercentage = 100;
    if (_worldPercentage > 100) _worldPercentage = 100;
  }
}

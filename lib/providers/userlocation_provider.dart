// lib/providers/userlocation_provider.dart

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/user_location.dart';

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
      print('Error updating user location: $e');
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

  /// Updates exploration percentages based on the user's location.
  ///
  /// **Note:** Replace the placeholder logic with actual implementation
  /// that calculates exploration based on geographical data.
  void _updateExploration(LatLng location) {
    // TODO: Implement real logic to calculate exploration based on location.

    // Placeholder logic: Increment percentages.
    _countryPercentage += 1;
    _continentPercentage += 1;
    _worldPercentage += 1;

    // Cap percentages at 100%.
    if (_countryPercentage > 100) _countryPercentage = 100;
    if (_continentPercentage > 100) _continentPercentage = 100;
    if (_worldPercentage > 100) _worldPercentage = 100;
  }

  /// Resets all exploration percentages to zero.
  void resetExploration() {
    _countryPercentage = 0;
    _continentPercentage = 0;
    _worldPercentage = 0;
    notifyListeners();
  }
}

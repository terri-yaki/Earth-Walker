// lib/screens/map_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../providers/userlocation_provider.dart';
import '../widgets/recenter_button.dart';
import '../widgets/hamburger_menu.dart';
import '../widgets/text.dart'; // Ensure this points to your custom text widget
import '../utils/constants.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  /// Initializes the map by fetching the user's location.
  Future<void> _initializeMap() async {
    try {
      // Fetch and update the user's location using the provider
      await Provider.of<UserLocationProvider>(context, listen: false)
          .updateUserLocation();

      // Move the map to the user's location with maximum zoom
      UserLocationProvider provider =
          Provider.of<UserLocationProvider>(context, listen: false);
      _mapController.move(provider.userLocation.coordinates, provider.currentZoom);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      // Handle any errors
      _showSnackBar('Failed to initialize map: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Displays a SnackBar with the given message.
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: customText(text: message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userLocationProvider = Provider.of<UserLocationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Earth Walker',
          style: AppTextStyles.appBarTitle,
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
      ),
      drawer: HamburgerMenu(),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Stack(
              children: [
                // Map Layer
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: userLocationProvider.userLocation.coordinates,
                    initialZoom: userLocationProvider.currentZoom,
                    maxZoom: 30.0, // Set maximum zoom level
                    onPositionChanged: (position, bool hasGesture) {
                      if (hasGesture) {
                        // User interacted with the map, disable auto-centering
                        userLocationProvider.setRecentered(false);
                      }

                      // If auto-centering is enabled, keep the map centered on the user
                      if (userLocationProvider.isRecentered) {
                        // Calculate the distance between current map center and user location
                        final distance = Distance().as(
                          LengthUnit.Meter,
                          position.center,
                          userLocationProvider.userLocation.coordinates,
                        );

                        // If the distance is greater than a small threshold, recenter the map
                        if (distance > 10) { // Threshold in meters
                          _mapController.move(
                            userLocationProvider.userLocation.coordinates,
                            userLocationProvider.currentZoom,
                            // Prevents triggering onPositionChanged again
                            // animate: false, // Uncomment if animate is necessary
                          );
                        }
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                      subdomains: ['a', 'b', 'c'],
                      additionalOptions: {
                        'user_agent': 'EarthWalkerApp/1.0.0',
                      },
                    ),
                    // User Location Marker with Custom Image
                    MarkerLayer(
                      markers: [
                        Marker(
                          width: 80.0,
                          height: 80.0,
                          point: userLocationProvider.userLocation.coordinates,
                          child: Container(
                            child: Image.asset(
                              'assets/img/user_m.png', // Ensure this path is correct
                              width: 40,
                              height: 40,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Positioned UI Elements
                Positioned(
                  top: 20,
                  left: 20,
                  child: Container(
                    padding: EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Country Explored: ${userLocationProvider.countryPercentage}%',
                          style: AppTextStyles.bodyText.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Continent Explored: ${userLocationProvider.continentPercentage}%',
                          style: AppTextStyles.bodyText.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'World Explored: ${userLocationProvider.worldPercentage}%',
                          style: AppTextStyles.bodyText1.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Recenter Button
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: RecenterButton(
                    mapController: _mapController,
                    onRecenter: _initializeMap,
                  ),
                ),
              ],
            ),
    );
  }
}

// lib/widgets/recenter_button.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/user_location.dart';
import '../widgets/text.dart'; // Ensure this points to your custom text widget
import '../utils/constants.dart';

class RecenterButton extends StatelessWidget {
  final MapController mapController;
  final Future<void> Function() onRecenter;

  const RecenterButton({
    Key? key,
    required this.mapController,
    required this.onRecenter,
  }) : super(key: key);

  /// Fetches the user's current location and recenters the map.
  Future<void> _handleRecenter(BuildContext context) async {
    await onRecenter();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: customText(text: 'Map recentered to your current location.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _handleRecenter(context),
      child: Icon(Icons.my_location),
      backgroundColor: Colors.green,
      tooltip: 'Recenter Map',
    );
  }
}

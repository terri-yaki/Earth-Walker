// lib/widgets/recenter_button.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../utils/l10n.dart';
import '../widgets/text.dart'; // Ensure this points to your custom text widget

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
    // Capture the messenger and the localised snack text BEFORE
    // the await. After `await onRecenter()` the BuildContext may
    // be stale (the user navigated away, the widget was disposed,
    // etc.) and looking it up via ScaffoldMessenger.of(context)
    // could throw or use a detached messenger.
    final messenger = ScaffoldMessenger.of(context);
    final l = L10n.of(context);
    await onRecenter();
    messenger.showSnackBar(
      SnackBar(
        content: CustomText(text: l.mapRecenteredSnack),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return FloatingActionButton(
      onPressed: () => _handleRecenter(context),
      backgroundColor: Colors.green,
      child: const Icon(Icons.my_location),
      tooltip: l.recenterMapTooltip,
    );
  }
}

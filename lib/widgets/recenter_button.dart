// lib/widgets/recenter_button.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../utils/l10n.dart';

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
    // Capture the localised snack text BEFORE the await. Looking
    // up L10n.of(context) after the await is unsafe because the
    // BuildContext may be stale (the user navigated away, the
    // widget was disposed, etc.).
    final l = L10n.of(context);
    try {
      await onRecenter();
    } catch (_) {
      // The map screen's _initializeMap catches and surfaces
      // errors via its own snackbar. If we also fired our
      // success snackbar here, the user would see two
      // contradictory messages back-to-back ("Failed to
      // initialize map…" then "Map recentered…"). Skip the
      // success message on any throw.
      return;
    }
    // After the await, the host widget tree may have been torn
    // down (e.g. the user pressed the system back button mid-
    // recenter). ScaffoldMessenger.of(context) on a disposed
    // BuildContext throws, so we guard with context.mounted
    // before doing the lookup.
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        // Plain Text: SnackBar already provides the right
        // color/contrast via its theme. The previous
        // CustomText wrapper forced color: Colors.black (from
        // AppTextStyles.defaultTextStyle) which clashes with
        // SnackBar's dark default surface in M2/M3.
        content: Text(l.mapRecenteredSnack),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return FloatingActionButton(
      onPressed: () => _handleRecenter(context),
      backgroundColor: Colors.green,
      tooltip: l.recenterMapTooltip,
      // child last — Flutter convention is for the widget's
      // child to be the final argument so the call site reads
      // "background, behaviour, child" top-to-bottom.
      child: const Icon(Icons.my_location),
    );
  }
}

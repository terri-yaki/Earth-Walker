// lib/screens/onboarding_screen.dart
//
// Shown on first app launch. Explains what Urbix HK does, asks for
// location permission, and on grant writes a SharedPreferences flag so
// subsequent launches skip straight to the map.
//
// Ponytail note: the welcome copy is intentionally short. A real
// onboarding flow with multiple pages / illustrations would be overkill
// for a prototype —three lines of text and one button is enough.

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/userlocation_provider.dart'
    show LocationPermissionDeniedException;
import '../utils/l10n.dart';
import 'map_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  /// SharedPreferences key for the "user has finished onboarding" flag.
  static const String prefsKeyOnboardingComplete = 'urbix.onboarding_complete';

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _busy = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // If the user already finished onboarding on a previous launch,
    // skip the welcome UI and go straight to the map.
    _skipIfAlreadyOnboarded();
  }

  Future<void> _skipIfAlreadyOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    if (prefs.getBool(OnboardingScreen.prefsKeyOnboardingComplete) == true) {
      _goToMap();
    }
  }

  Future<void> _onGetStarted() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _errorMessage = null;
    });

    final l = L10n.of(context);
    try {
      // Ensure location services are enabled at the device level.
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted) return;
      if (!serviceEnabled) {
        setState(() {
          _busy = false;
          _errorMessage = l.onboardingLocOff;
        });
        return;
      }

      // Request permission. Geolocator surfaces denied / deniedForever
      // distinctly so we can tell the user whether to try again or to
      // open system Settings.
      LocationPermission permission = await Geolocator.checkPermission();
      if (!mounted) return;
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (!mounted) return;
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _busy = false;
          _errorMessage = l.onboardingPermDeniedForever;
        });
        return;
      }
      if (permission == LocationPermission.denied) {
        setState(() {
          _busy = false;
          _errorMessage = l.onboardingPermDenied;
        });
        return;
      }

      // Permission granted —remember and proceed.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(OnboardingScreen.prefsKeyOnboardingComplete, true);
      if (!mounted) return;
      _goToMap();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        // Map the typed permission-denied exception to the
        // localised "permission denied" copy. Everything else
        // falls through to the generic "could not request
        // location" prefix, which is itself localised.
        _errorMessage = e is LocationPermissionDeniedException
            ? l.onboardingPermDenied
            : '${l.onboardingLocErrorPrefix} $e';
      });
    }
  }

  void _goToMap() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MapScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.explore,
                size: 96,
                color: Colors.green,
              ),
              const SizedBox(height: 24),
              Text(
                L10n.of(context).appTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'PixelFont',
                  fontSize: 32,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                L10n.of(context).onboardingPitch,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 32),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _busy ? null : _onGetStarted,
                child: _busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        L10n.of(context).onboardingGetStarted,
                        style: const TextStyle(
                          fontSize: 18,
                          fontFamily: 'PixelFont',
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

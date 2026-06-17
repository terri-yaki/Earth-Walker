import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:urbix/screens/onboarding_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows the welcome UI on a fresh install', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
    await tester.pump(); // let the post-frame initState run

    expect(find.text('Urbix HK'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.byIcon(Icons.explore), findsOneWidget);
  });

  testWidgets('onboarding-complete flag is exposed as a stable constant',
      (tester) async {
    // Trivial guard so the constant never silently changes; onboarding
    // state lives in SharedPreferences under this key.
    expect(OnboardingScreen.prefsKeyOnboardingComplete,
        'urbix.onboarding_complete');
  });
}

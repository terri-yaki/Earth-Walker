import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:urbix/screens/onboarding_screen.dart';
import 'package:urbix/utils/l10n.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget _app() => MaterialApp(
        localizationsDelegates: const [L10nDelegate()],
        supportedLocales: kSupportedLocales,
        home: const OnboardingScreen(),
      );

  testWidgets('shows the English welcome UI on a fresh install',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump(); // let the post-frame initState run

    expect(find.text('Urbix HK'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.byIcon(Icons.explore), findsOneWidget);
  });

  testWidgets('renders zh-HK copy when the device locale is zh-HK',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh', 'HK'),
        localizationsDelegates: const [L10nDelegate()],
        supportedLocales: kSupportedLocales,
        home: const OnboardingScreen(),
      ),
    );
    await tester.pump();

    expect(find.text('Urbix 擐葛'), findsOneWidget);
    expect(find.text('??雿輻'), findsOneWidget);
  });

  testWidgets('onboarding-complete flag is exposed as a stable constant',
      (tester) async {
    // Trivial guard so the constant never silently changes; onboarding
    // state lives in SharedPreferences under this key.
    expect(OnboardingScreen.prefsKeyOnboardingComplete,
        'urbix.onboarding_complete');
  });
}

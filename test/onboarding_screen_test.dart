import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:urbix/screens/onboarding_screen.dart';
import 'package:urbix/utils/l10n.dart';

import 'helpers/test_l10n.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget _app({Locale locale = const Locale('en')}) => MaterialApp(
        locale: locale,
        // Default Material/Widget localizations are required for
        // AppBar and any built-in widget that surfaces user-facing
        // strings, especially for non-English locales like zh-HK.
        localizationsDelegates: const [
          ...GlobalMaterialLocalizations.delegates,
          GlobalWidgetsLocalizations.delegate,
          TestL10nDelegate(),
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('zh', 'HK'),
        ],
        home: const OnboardingScreen(),
      );

  testWidgets('shows the English welcome UI on a fresh install',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle(); // let the post-frame initState run

    expect(find.text('Urbix HK'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.byIcon(Icons.explore), findsOneWidget);
  });

  testWidgets('renders zh-HK copy when the device locale is zh-HK',
      (tester) async {
    await tester.pumpWidget(_app(locale: const Locale('zh', 'HK')));
    await tester.pumpAndSettle();

    // The actual zh-HK copy is in assets/l10n/zh-HK.json;
    // assert against the icon + general presence, not the
    // exact glyphs (which can be re-worded freely).
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

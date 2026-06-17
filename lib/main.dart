// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import your custom providers
import 'providers/userlocation_provider.dart';
import 'providers/achievement_provider.dart';
import 'providers/medal_provider.dart';

// Import your screens and utilities
import 'screens/map_screen.dart';
import 'utils/constants.dart';

void main() {
  runApp(const EarthWalkerApp());
}

class EarthWalkerApp extends StatelessWidget {
  const EarthWalkerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserLocationProvider>(
          create: (_) => UserLocationProvider(),
        ),
        // Derive achievements from the location provider: every time
        // UserLocationProvider notifies, push its percentages through.
        ChangeNotifierProxyProvider<UserLocationProvider, AchievementProvider>(
          create: (_) => AchievementProvider(),
          update: (_, location, achievements) {
            achievements ??= AchievementProvider();
            achievements.updateExploration(
              location.countryPercentage,
              location.continentPercentage,
              location.worldPercentage,
            );
            return achievements;
          },
        ),
        // Same for medals: world % drives the unlock thresholds.
        ChangeNotifierProxyProvider<UserLocationProvider, MedalProvider>(
          create: (_) => MedalProvider(),
          update: (_, location, medals) {
            medals ??= MedalProvider();
            medals.checkAndAwardMedals(location.worldPercentage);
            return medals;
          },
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false, // Optional: Removes the debug banner
        title: 'Earth Walker',
        theme: ThemeData(
          primarySwatch: Colors.green,
          fontFamily: 'PixelFont', // Ensure this matches your pubspec.yaml
          textTheme: TextTheme(
            headlineLarge: AppTextStyles.appBarTitle,
            headlineSmall: AppTextStyles.drawerHeader,
            bodyLarge: AppTextStyles.bodyText1,
            bodyMedium: AppTextStyles.bodyText2,
            // Define other text styles as needed
          ),
        ),
        home: const MapScreen(),
      ),
    );
  }
}

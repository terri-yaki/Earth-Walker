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
        ChangeNotifierProvider<AchievementProvider>(
          create: (_) => AchievementProvider(),
        ),
        ChangeNotifierProvider<MedalProvider>(
          create: (_) => MedalProvider(),
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

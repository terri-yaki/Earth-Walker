// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import your custom providers
import 'providers/userlocation_provider.dart';
// Import other providers if any

// Import your screens and utilities
import 'screens/map_screen.dart';
import 'utils/constants.dart';

void main() {
  runApp(EarthWalkerApp());
}

class EarthWalkerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserLocationProvider>(
          create: (_) => UserLocationProvider(),
        ),
        // Add other providers here if needed
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
        home: MapScreen(),
      ),
    );
  }
}

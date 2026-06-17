import 'package:flutter/material.dart';

/// Manages achievement logic, such as calculating
/// how much of a country/continent/world is explored
/// and unlocking new achievements.
class AchievementProvider with ChangeNotifier {
  // Example data fields
  int _countryExplored = 0;
  int _continentExplored = 0;
  int _worldExplored = 0;

  // Achievements unlocked
  final List<String> _unlockedAchievements = [];

  // Example thresholds for awarding achievements
  final Map<String, int> _achievementThresholds = {
    'Walker': 10,
    'Pioneer': 20,
    'Traveller': 30,
    'Explorer': 40,
    'Coloniser': 50,
    'Dominator': 80,
    'Are you sure you’re not cheating?': 99, // 99%+
  };

  // Getters
  int get countryExplored => _countryExplored;
  int get continentExplored => _continentExplored;
  int get worldExplored => _worldExplored;

  List<String> get unlockedAchievements => List.unmodifiable(_unlockedAchievements);

  /// Update the user’s exploration progress.
  /// In a real scenario, these might be computed from GPS data or MapProvider data.
  void updateExploration(int countryValue, int continentValue, int worldValue) {
    _countryExplored = countryValue.clamp(0, 100);
    _continentExplored = continentValue.clamp(0, 100);
    _worldExplored = worldValue.clamp(0, 100);

    _checkForNewAchievements();
    notifyListeners();
  }

  /// Check if any new achievements are unlocked 
  /// based on the user’s updated exploration progress.
  void _checkForNewAchievements() {
    // For demonstration, let’s track just worldExplored
    final currentProgress = _worldExplored;
    _achievementThresholds.forEach((title, threshold) {
      if (currentProgress >= threshold && !_unlockedAchievements.contains(title)) {
        _unlockedAchievements.add(title);
      }
    });
  }
}

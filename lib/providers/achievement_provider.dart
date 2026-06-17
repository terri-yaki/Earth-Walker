import 'package:flutter/material.dart';

/// Return the achievement titles that appear in [current] but not in
/// [previous], in [current]'s order. Used by the map view to surface
/// a 'Badge unlocked: X' snackbar when the user crosses a threshold.
///
/// Pure function so it's unit-testable without a ChangeNotifier.
List<String> newlyUnlockedBetween(
  List<String> previous,
  List<String> current,
) {
  final prior = previous.toSet();
  return current.where((title) => !prior.contains(title)).toList();
}

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

  /// All achievement titles and the world-% threshold required to unlock them.
  Map<String, int> get achievementThresholds =>
      Map.unmodifiable(_achievementThresholds);

  /// True if the given title is already in the unlocked list.
  bool isUnlocked(String title) => _unlockedAchievements.contains(title);

  /// Clear all unlocked achievements and notify listeners. Used by the
  /// drawer's Reset Progress action. The thresholds map is left intact;
  /// the user can re-earn the same badges by re-exploring.
  void resetAchievements() {
    if (_unlockedAchievements.isEmpty) return;
    _unlockedAchievements.clear();
    notifyListeners();
  }

  /// Update the user’s exploration progress.
  /// In a real scenario, these would be derived from GPS / location history.
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

import 'package:flutter/material.dart';

/// Manages logic related to awarding and displaying medals
/// for certain achievements or exploration milestones.
class MedalProvider with ChangeNotifier {
  // Example structure for storing medals. 
  // Each medal might have an ID, a name, description, and a condition.
  final List<Medal> _medals = [
    Medal(id: 1, name: 'Walker Medal', condition: 10),
    Medal(id: 2, name: 'Pioneer Medal', condition: 20),
    Medal(id: 3, name: 'Traveller Medal', condition: 30),
    Medal(id: 4, name: 'Explorer Medal', condition: 40),
    Medal(id: 5, name: 'Coloniser Medal', condition: 50),
    Medal(id: 6, name: 'Dominator Medal', condition: 80),
    Medal(id: 7, name: 'Are you sure you’re not cheating?', condition: 99),
  ];

  // Holds the IDs of medals already awarded
  final List<int> _awardedMedals = [];

  // Getters
  List<Medal> get medals => List.unmodifiable(_medals);
  List<int> get awardedMedals => List.unmodifiable(_awardedMedals);

  /// Check if the user’s progress meets the condition for awarding a medal.
  /// For example, if `progress` is the user’s overall world exploration percentage,
  /// this method checks which medals are unlocked.
  void checkAndAwardMedals(int progress) {
    for (final medal in _medals) {
      if (progress >= medal.condition && !_awardedMedals.contains(medal.id)) {
        _awardedMedals.add(medal.id);
      }
    }
    notifyListeners();
  }

  bool isMedalAwarded(int medalId) {
    return _awardedMedals.contains(medalId);
  }
}

/// A simple data model for a medal.
// You could expand this with images, descriptions, etc.
class Medal {
  final int id;
  final String name;
  final int condition; // The percentage threshold required

  Medal({
    required this.id,
    required this.name,
    required this.condition,
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:urbix/providers/achievement_provider.dart';

void main() {
  group('AchievementProvider', () {
    test('starts with no unlocked achievements', () {
      final p = AchievementProvider();
      expect(p.unlockedAchievements, isEmpty);
      expect(p.isUnlocked('Walker'), isFalse);
    });

    test('unlocks achievements as world % crosses thresholds', () {
      final p = AchievementProvider();
      p.updateExploration(0, 0, 9);
      expect(p.unlockedAchievements, isEmpty,
          reason: 'below first threshold of 10');

      p.updateExploration(0, 0, 10);
      expect(p.unlockedAchievements, contains('Walker'));

      p.updateExploration(0, 0, 25);
      expect(p.unlockedAchievements,
          containsAll(<String>['Walker', 'Pioneer', 'Traveller']));
    });

    test('clamps percentages to 0..100', () {
      final p = AchievementProvider();
      p.updateExploration(150, -5, 200);
      expect(p.countryExplored, 100);
      expect(p.continentExplored, 0);
      expect(p.worldExplored, 100);
    });

    test('does not re-unlock an already-unlocked achievement', () {
      final p = AchievementProvider();
      p.updateExploration(0, 0, 50);
      final afterFirst = List<String>.from(p.unlockedAchievements);
      p.updateExploration(0, 0, 50);
      expect(p.unlockedAchievements, afterFirst);
    });

    test('resetAchievements clears all unlocked achievements', () {
      final p = AchievementProvider();
      p.updateExploration(0, 0, 99);
      expect(p.unlockedAchievements, isNotEmpty);
      p.resetAchievements();
      expect(p.unlockedAchievements, isEmpty);
    });

    test('resetAchievements on empty state does not notify', () {
      final p = AchievementProvider();
      var notifyCount = 0;
      p.addListener(() => notifyCount++);
      p.resetAchievements();
      expect(notifyCount, 0);
    });
  });
}

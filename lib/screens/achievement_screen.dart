// lib/screens/achievement_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/achievement_provider.dart';
import '../utils/constants.dart';

class AchievementScreen extends StatelessWidget {
  const AchievementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final achievementProvider = context.watch<AchievementProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Achievements',
          style: AppTextStyles.appBarTitle,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildPercentageRow(
              'Country', achievementProvider.countryExplored),
          const SizedBox(height: 10),
          _buildPercentageRow(
              'Continent', achievementProvider.continentExplored),
          const SizedBox(height: 10),
          _buildPercentageRow('World', achievementProvider.worldExplored),
          const SizedBox(height: 24),
          Text(
            'Badges',
            style: AppTextStyles.achievementTitle,
          ),
          const SizedBox(height: 8),
          if (achievementProvider.unlockedAchievements.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'No badges yet. Keep exploring to unlock your first one!',
                style: AppTextStyles.bodyText1,
              ),
            )
          else
            ...achievementProvider.achievementThresholds.entries
                .map((entry) => _buildAchievementTile(
                      title: entry.key,
                      threshold: entry.value,
                      unlocked: achievementProvider.isUnlocked(entry.key),
                    )),
        ],
      ),
    );
  }

  Widget _buildPercentageRow(String title, int percentage) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$title Exploration:',
          style: AppTextStyles.achievementTitle,
        ),
        Text(
          '$percentage%',
          style: AppTextStyles.achievementPercentage,
        ),
      ],
    );
  }

  Widget _buildAchievementTile({
    required String title,
    required int threshold,
    required bool unlocked,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        unlocked ? Icons.emoji_events : Icons.lock_outline,
        color: unlocked ? Colors.amber : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: unlocked ? FontWeight.bold : FontWeight.normal,
          color: unlocked ? Colors.black : Colors.grey.shade600,
        ),
      ),
      subtitle: Text('Unlocked at $threshold% world exploration'),
    );
  }
}

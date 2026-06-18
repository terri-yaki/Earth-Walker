// lib/screens/achievement_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/achievement_provider.dart';
import '../utils/constants.dart';
import '../utils/l10n.dart';

class AchievementScreen extends StatelessWidget {
  const AchievementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final achievementProvider = context.watch<AchievementProvider>();

    final l = L10n.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l.screenAchievements,
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
            l.badgesHeader,
            style: AppTextStyles.achievementTitle,
          ),
          const SizedBox(height: 8),
          if (achievementProvider.unlockedAchievements.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                l.badgesEmpty,
                style: AppTextStyles.bodyText1,
              ),
            )
          else
            ...achievementProvider.achievementThresholds.entries
                .map((entry) => _buildAchievementTile(
                      title: entry.key,
                      threshold: entry.value,
                      unlocked: achievementProvider.isUnlocked(entry.key),
                      unlockedAtLabel: l.badgeUnlockedAt,
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
    required String unlockedAtLabel,
  }) {
    final tier = tierForThreshold(threshold);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        unlocked ? Icons.emoji_events : Icons.lock_outline,
        color: unlocked ? _tierColor(tier) : Colors.grey,
      ),
      title: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: unlocked ? FontWeight.bold : FontWeight.normal,
              color: unlocked ? Colors.black : Colors.grey.shade600,
            ),
          ),
          if (unlocked) ...[
            const SizedBox(width: 8),
            Text(
              _tierLabel(tier),
              style: TextStyle(
                fontSize: 11,
                color: _tierColor(tier),
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ],
      ),
      subtitle: Text('$unlockedAtLabel $threshold% world exploration'),
    );
  }

  Color _tierColor(AchievementTier tier) {
    switch (tier) {
      case AchievementTier.gold:
        return const Color(0xFFD4A017); // muted gold
      case AchievementTier.silver:
        return const Color(0xFF8E96A1); // muted silver
      case AchievementTier.bronze:
        return const Color(0xFFB87333); // muted bronze / copper
    }
  }

  String _tierLabel(AchievementTier tier) {
    switch (tier) {
      case AchievementTier.gold:
        return 'GOLD';
      case AchievementTier.silver:
        return 'SILVER';
      case AchievementTier.bronze:
        return 'BRONZE';
    }
  }
}

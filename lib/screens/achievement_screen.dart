// lib/screens/achievement_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/achievement_provider.dart';
import '../utils/constants.dart';
import '../utils/l10n.dart';
import '../utils/tier_styling.dart';

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
          _buildPercentageRow(l, l.explorationCountry,
              achievementProvider.countryExplored),
          const SizedBox(height: 10),
          _buildPercentageRow(l, l.explorationContinent,
              achievementProvider.continentExplored),
          const SizedBox(height: 10),
          _buildPercentageRow(l, l.explorationWorld,
              achievementProvider.worldExplored),
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
                      l: l,
                      title: entry.key,
                      threshold: entry.value,
                      unlocked: achievementProvider.isUnlocked(entry.key),
                      unlockedAtLabel: l.badgeUnlockedAt,
                    )),
        ],
      ),
    );
  }

  Widget _buildPercentageRow(L10n l, String title, int percentage) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          // '$title Exploration:' as one template would be hard to
          // translate (e.g. Chinese puts the colon and word order
          // differently). Pass the label and suffix in separately
          // so the l10n layer can glue them with locale rules.
          '$title ${l.explorationSuffix}',
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
    required L10n l,
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
        color: unlocked ? tierColor(tier) : Colors.grey,
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
              tierLabel(tier, l),
              style: TextStyle(
                fontSize: 11,
                color: tierColor(tier),
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
          '$unlockedAtLabel $threshold% ${l.explorationWorldPercent}'),
    );
  }
}

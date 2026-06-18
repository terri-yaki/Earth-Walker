// lib/screens/medal_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/achievement_provider.dart'
    show tierForThreshold, AchievementTier;
import '../providers/medal_provider.dart';
import '../utils/l10n.dart';

class MedalScreen extends StatelessWidget {
  const MedalScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final provider = context.watch<MedalProvider>();
    final medals = provider.medals;
    final awardedCount = provider.awardedMedals.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.screenMedals),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              '$awardedCount of ${medals.length} ${l.medalsEarned}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...medals.map((medal) {
            final awarded = provider.isMedalAwarded(medal.id);
            final tier = tierForThreshold(medal.condition);
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                awarded ? Icons.emoji_events : Icons.lock_outline,
                color: awarded ? _tierColor(tier) : Colors.grey,
              ),
              title: Row(
                children: [
                  Flexible(
                    child: Text(
                      medal.name,
                      style: TextStyle(
                        fontWeight:
                            awarded ? FontWeight.bold : FontWeight.normal,
                        color: awarded ? Colors.black : Colors.grey.shade600,
                      ),
                    ),
                  ),
                  if (awarded) ...[
                    const SizedBox(width: 8),
                    Text(
                      _tierLabel(tier, l),
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
              subtitle: Text(
                '${l.medalsAwardedAt} ${medal.condition}% ${l.explorationWorldPercent}',
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _tierColor(AchievementTier tier) {
    switch (tier) {
      case AchievementTier.gold:
        return const Color(0xFFD4A017);
      case AchievementTier.silver:
        return const Color(0xFF8E96A1);
      case AchievementTier.bronze:
        return const Color(0xFFB87333);
    }
  }

  String _tierLabel(AchievementTier tier, L10n l) {
    switch (tier) {
      case AchievementTier.gold:
        return l.tierGold;
      case AchievementTier.silver:
        return l.tierSilver;
      case AchievementTier.bronze:
        return l.tierBronze;
    }
  }
}

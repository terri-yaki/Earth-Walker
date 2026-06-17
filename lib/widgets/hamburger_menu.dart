// lib/widgets/hamburger_menu.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/achievement_provider.dart';
import '../providers/medal_provider.dart';
import '../providers/userlocation_provider.dart';
import '../screens/achievement_screen.dart';
import '../screens/medal_screen.dart';
import '../utils/progress_summary.dart';

class HamburgerMenu extends StatelessWidget {
  const HamburgerMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.green,
            ),
            child: Text(
              'Urbix HK',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontFamily: 'PixelFont',
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.emoji_events),
            title: const Text('Achievements'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AchievementScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.star),
            title: const Text('Medals'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MedalScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.restart_alt, color: Colors.red),
            title: const Text(
              'Reset Progress',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => _confirmReset(context),
          ),
        ],
      ),
    );
  }

  /// Show a confirmation dialog before wiping the user's visited cells,
  /// unlocked achievements, and awarded medals. Includes a 'Copy' button
  /// so the user can grab a text summary of their progress first.
  Future<void> _confirmReset(BuildContext context) async {
    final location = context.read<UserLocationProvider>();
    final achievements = context.read<AchievementProvider>();
    final medals = context.read<MedalProvider>();

    final summary = formatProgressSummary(
      cellsVisited: location.uniqueCellsVisited,
      badgesUnlocked: achievements.unlockedAchievements.length,
      medalsEarned: medals.awardedMedals.length,
      metersWalked: location.totalDistanceMeters,
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset progress?'),
        content: Text(
          'This will permanently clear your exploration history.\n\n$summary',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: summary));
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                const SnackBar(content: Text('Progress copied to clipboard.')),
              );
            },
            child: const Text('Copy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    location.resetExploration();
    achievements.resetAchievements();
    medals.resetMedals();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Progress reset.')),
    );
  }
}

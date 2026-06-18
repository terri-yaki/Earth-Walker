// lib/widgets/hamburger_menu.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/achievement_provider.dart';
import '../providers/medal_provider.dart';
import '../providers/userlocation_provider.dart';
import '../screens/achievement_screen.dart';
import '../screens/districts_screen.dart';
import '../screens/medal_screen.dart';
import '../utils/l10n.dart';
import '../utils/progress_summary.dart';

class HamburgerMenu extends StatelessWidget {
  const HamburgerMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.green,
            ),
            child: Text(
              l.appTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontFamily: 'PixelFont',
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.emoji_events),
            title: Text(l.menuAchievements),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AchievementScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.star),
            title: Text(l.menuMedals),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MedalScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.location_city),
            title: Text(l.menuDistricts),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DistrictsScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.restart_alt, color: Colors.red),
            title: Text(
              l.menuReset,
              style: const TextStyle(color: Colors.red),
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
    final l = L10n.of(context);
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
        title: Text(l.resetDialogTitle),
        content: Text(
          '${l.resetDialogBody}\n\n$summary',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l.resetDialogCancel),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: summary));
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                SnackBar(content: Text(l.progressCopied)),
              );
            },
            child: Text(l.resetDialogCopy),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l.resetDialogConfirm),
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
      SnackBar(content: Text(l.progressResetDone)),
    );
  }
}

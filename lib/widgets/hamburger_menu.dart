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
            leading: const Icon(Icons.ios_share),
            title: Text(l.menuShare),
            onTap: () => _showShareDialog(context),
          ),
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

  /// Show a dialog with a copy-paste-able snapshot of the user's
  /// current progress. Another Urbix HK user can paste it into the
  /// "Compare" entry (FEAT-4 in ISSUES.md) to see a side-by-side
  /// comparison. Falls back to the plain text summary if the
  /// snapshot fails to build (it never should, but defensive).
  Future<void> _showShareDialog(BuildContext context) async {
    final l = L10n.of(context);
    final location = context.read<UserLocationProvider>();
    final achievements = context.read<AchievementProvider>();
    final medals = context.read<MedalProvider>();

    final snapshot = ProgressSnapshot.fromValues(
      cellsVisited: location.uniqueCellsVisited,
      badgesUnlocked: achievements.unlockedAchievements.length,
      medalsEarned: medals.awardedMedals.length,
      metersWalked: location.totalDistanceMeters,
      daysExplored: location.daysExplored,
      currentStreakDays: location.currentStreakDays,
    );
    final snapshotText = encodeProgressSnapshot(snapshot);
    final summary = formatProgressSummary(
      cellsVisited: snapshot.cellsVisited,
      badgesUnlocked: snapshot.badgesUnlocked,
      medalsEarned: snapshot.medalsEarned,
      metersWalked: snapshot.metersWalked,
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.shareDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              summary,
              style: AppTextStyles.bodyText1,
            ),
            const SizedBox(height: 12),
            SelectableText(
              snapshotText,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: Colors.black54,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l.resetDialogCancel),
          ),
          TextButton(
            onPressed: () {
              // Copy the SNAPSHOT (not the summary) so the
              // receiver can parse it and compare.
              Clipboard.setData(ClipboardData(text: snapshotText));
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                SnackBar(content: Text(l.shareDialogCopied)),
              );
              Navigator.of(dialogContext).pop();
            },
            child: Text(l.shareDialogCopy),
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

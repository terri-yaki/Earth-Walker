// lib/widgets/hamburger_menu.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/achievement_provider.dart';
import '../providers/medal_provider.dart';
import '../providers/userlocation_provider.dart';
import '../screens/achievement_screen.dart';
import '../screens/districts_screen.dart';
import '../screens/medal_screen.dart';
import '../utils/constants.dart';
import '../utils/l10n.dart';
import '../utils/progress_summary.dart';
import '../utils/share_text.dart';

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
                MaterialPageRoute(
                    builder: (context) => const AchievementScreen()),
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
                MaterialPageRoute(
                    builder: (context) => const DistrictsScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.ios_share),
            title: Text(l.menuShare),
            onTap: () => showShareDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.compare_arrows),
            title: Text(l.menuCompare),
            onTap: () => _showCompareDialog(context),
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
  /// current progress. The "Share" action hands the brag message
  /// (with snapshot embedded) to the OS share sheet so the user
  /// can post to Instagram, WhatsApp, X, Threads, Telegram etc.
  /// without leaving the app. The "Copy" action stays for users
  /// who just want the raw snapshot text (e.g. for Compare).
  ///
  /// Public + static so the map screen can invoke it from the
  /// streak-milestone auto-prompt snackbar action and from the
  /// HUD share icon without going through the drawer.
  static Future<void> showShareDialog(BuildContext context) async {
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
      // Cell label is localised; the rest are short data nouns
      // that read naturally in either language (English fallback
      // is intentional and matches the compare-dialog policy).
      cellsLabel: snapshot.cellsVisited == 1 ? l.cellSingular : l.cellPlural,
      badgesLabel: 'badges',
      medalsLabel: 'medals',
      distanceLabel: 'km',
    );
    // Smart default brag: if the user has a real streak going
    // (>= 2 days so "today" doesn't count as a brag), surface the
    // streak brag. Otherwise the generic "I've been exploring"
    // line. The user can still edit in the share sheet.
    final bragLine = snapshot.currentStreakDays >= 2
        ? l.shareBragStreak
        : l.shareBragDefault;
    final shareText = formatShareText(
      snapshot: snapshot,
      bragLine: bragLine,
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
            },
            child: Text(l.shareDialogCopy),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.ios_share),
            label: Text(l.shareDialogShare),
            onPressed: () async {
              // Pop the dialog first so the share sheet pops over
              // the map, not over the dialog (matters on Android
              // where the dialog is a separate window).
              Navigator.of(dialogContext).pop();
              // share_plus: Rect is required on iPad (popover
              // anchor). Pass a zero Rect on phones —the OS
              // ignores it. ponytail: a future iPad-only
              // pass-through of the share button's RenderBox
              // would tighten the popover arrow to the actual
              // tap point, but it's invisible on phone.
              await Share.share(
                shareText,
                subject: l.shareDialogTitle,
                sharePositionOrigin: const Rect.fromLTWH(0, 0, 0, 0),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.shareDialogShared)),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  /// Show a dialog where the user can paste a friend's snapshot
  /// string (copied from another Urbix HK user). On Compare, parse
  /// the input, build the local user's snapshot, run
  /// [ProgressSnapshot.compare], and show a result dialog with
  /// the per-field deltas. Parse failure surfaces a SnackBar.
  Future<void> _showCompareDialog(BuildContext context) async {
    final l = L10n.of(context);
    final controller = TextEditingController();

    // Show the input dialog. We use a stateful local widget so
    // the dialog can keep its own TextEditingController for the
    // pasted text.
    final pasted = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.compareDialogTitle),
        content: TextField(
          controller: controller,
          maxLines: 5,
          minLines: 3,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l.compareDialogPasteHint,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l.compareDialogClose),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: Text(l.compareDialogCompare),
          ),
        ],
      ),
    );
    // The user closed without comparing.
    if (pasted == null) return;

    // Build the local snapshot for the compare side.
    final location = context.read<UserLocationProvider>();
    final achievements = context.read<AchievementProvider>();
    final medals = context.read<MedalProvider>();
    final mine = ProgressSnapshot.fromValues(
      cellsVisited: location.uniqueCellsVisited,
      badgesUnlocked: achievements.unlockedAchievements.length,
      medalsEarned: medals.awardedMedals.length,
      metersWalked: location.totalDistanceMeters,
      daysExplored: location.daysExplored,
      currentStreakDays: location.currentStreakDays,
    );

    final theirs = parseProgressSnapshot(pasted);
    if (theirs == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.compareDialogParseFailed)),
        );
      }
      return;
    }

    if (!context.mounted) return;
    await _showCompareResultDialog(context, mine, theirs);
  }

  /// Show the per-field deltas produced by
  /// [ProgressSnapshot.compare]. If every field is tied, show the
  /// "tied on every metric" message instead of a list.
  Future<void> _showCompareResultDialog(
    BuildContext context,
    ProgressSnapshot mine,
    ProgressSnapshot theirs,
  ) async {
    final l = L10n.of(context);
    final deltas = ProgressSnapshot.compare(
      other: theirs,
      yours: mine,
      // Field labels are plain English —the badges/medals
      // themselves aren't localised, and the comparison strings
      // read most naturally as the same nouns the user sees on
      // the achievement / medal screens.
      cellsLabel: 'cells',
      distanceLabel: 'km',
      badgesLabel: 'badges',
      medalsLabel: 'medals',
      daysLabel: 'days',
      streakLabel: 'day streak',
      youWinLabel: l.compareDialogYouWin,
      theyWinLabel: l.compareDialogTheyWin,
    );
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.compareDialogTitle),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l.compareDialogYou,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    l.compareDialogThem,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (deltas.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    l.compareDialogTied,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                )
              else
                ...deltas.map((line) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Text(line),
                    )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l.compareDialogClose),
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
      cellsLabel: location.uniqueCellsVisited == 1
          ? l.cellSingular
          : l.cellPlural,
      badgesLabel: 'badges',
      medalsLabel: 'medals',
      distanceLabel: 'km',
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

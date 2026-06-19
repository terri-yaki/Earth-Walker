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
      cellsLabel:
          pluralize(snapshot.cellsVisited, l.cellSingular, l.cellPlural),
      badgesLabel: 'badges',
      medalsLabel: 'medals',
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
            child: Text(l.shareDialogCancel),
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

    // The TextEditingController for the paste field lives in a
    // dedicated stateful widget ([_CompareDialog]) so it gets
    // disposed when the dialog closes. The previous inline
    // controller was created here and never disposed, leaking a
    // controller (and its listeners) every time the user opened
    // Compare. After ~10 opens, that's 10 leaked controllers
    // and growing.
    final pasted = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _CompareDialog(l: l),
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
    // Field labels are plain English —the badges/medals
    // themselves aren't localised, and the comparison strings
    // read most naturally as the same nouns the user sees on
    // the achievement / medal screens.
    //
    // The four count-noun labels (cells / badges / medals /
    // days) are plural-aware via [pluralize]: the caller
    // passes the singular form for `abs(delta) == 1` and the
    // plural form otherwise. Without this, "1 cells (you
    // win)" would leak into the UI —the kind of tiny grammar
    // bug that earns user trust losses even when the
    // underlying numbers are correct.
    final dCells = theirs.cellsVisited - mine.cellsVisited;
    final dBadges = theirs.badgesUnlocked - mine.badgesUnlocked;
    final dMedals = theirs.medalsEarned - mine.medalsEarned;
    final dDays = theirs.daysExplored - mine.daysExplored;
    final cellsLabel = pluralize(dCells, 'cell', 'cells');
    final badgesLabel = pluralize(dBadges, 'badge', 'badges');
    final medalsLabel = pluralize(dMedals, 'medal', 'medals');
    final daysLabel = pluralize(dDays, 'day', 'days');
    // "day streak" reads naturally in both singular and
    // plural positions ("1 day streak", "5 day streak") —
    // "5 day streak" is the standard compound-noun phrasing
    // here ("she's on a 5 day streak"). The label is a single
    // string because "day" in this position is part of the
    // compound noun phrase, not a counted noun.
    const streakLabel = 'day streak';
    final deltas = ProgressSnapshot.compare(
      other: theirs,
      yours: mine,
      cellsLabel: cellsLabel,
      distanceLabel: 'km',
      badgesLabel: badgesLabel,
      medalsLabel: medalsLabel,
      daysLabel: daysLabel,
      streakLabel: streakLabel,
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
      cellsLabel: pluralize(
        location.uniqueCellsVisited,
        l.cellSingular,
        l.cellPlural,
      ),
      badgesLabel: 'badges',
      medalsLabel: 'medals',
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

/// Dialog that asks the user to paste a friend's snapshot. Owns
/// the [TextEditingController] for the paste field so the
/// controller's listeners are disposed when the dialog closes.
/// Without this, every Compare open would leak a controller
/// (the inline-controller pattern in [HamburgerMenu._showCompareDialog]
/// had exactly this bug).
class _CompareDialog extends StatefulWidget {
  final L10n l;
  const _CompareDialog({required this.l});

  @override
  State<_CompareDialog> createState() => _CompareDialogState();
}

class _CompareDialogState extends State<_CompareDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.l.compareDialogTitle),
      content: TextField(
        controller: _controller,
        maxLines: 5,
        minLines: 3,
        autofocus: true,
        decoration: InputDecoration(
          hintText: widget.l.compareDialogPasteHint,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.l.compareDialogClose),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: Text(widget.l.compareDialogCompare),
        ),
      ],
    );
  }
}

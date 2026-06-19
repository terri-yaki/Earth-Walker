// lib/screens/map_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../providers/achievement_provider.dart';
import '../providers/userlocation_provider.dart';
import '../widgets/recenter_button.dart';
import '../widgets/hamburger_menu.dart';
import '../widgets/text.dart'; // Ensure this points to your custom text widget
import '../utils/constants.dart';
import '../utils/exploration_suggestion.dart';
import '../utils/format_distance.dart';
import '../utils/l10n.dart';
import '../utils/progress_summary.dart';
import '../utils/streak_milestones.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  bool _isLoading = true;

  /// Snapshot of unlocked achievements at the time of the last check.
  /// Used to detect new unlocks on each AchievementProvider notification
  /// and show a one-shot 'Badge unlocked: X' snackbar.
  List<String> _lastSeenUnlocked = const <String>[];

  /// Highest currentStreakDays we've observed in this session.
  /// Used to detect a streak *increase* (not just a recompute)
  /// before we prompt the user to share. Initialised in initState
  /// from the provider's current value so a returning user with
  /// a 14-day streak doesn't get re-prompted for thresholds they
  /// already crossed in a previous session.
  int _lastSeenStreak = 0;

  /// Thresholds (in days) we've already shown the
  /// "Share your streak?" prompt for. Pre-seeded in initState
  /// from [_lastSeenStreak] so a returning user with an existing
  /// streak isn't re-prompted.
  final Set<int> _streakThresholdsPrompted = <int>{};

  @override
  void initState() {
    super.initState();
    _initializeMap();
    // Listen for new badge unlocks and surface a snackbar. We can't do
    // this in build() (would re-trigger on every rebuild); a listener
    // fires only when the provider actually notifies.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final achievements =
          Provider.of<AchievementProvider>(context, listen: false);
      _lastSeenUnlocked = List<String>.from(achievements.unlockedAchievements);
      achievements.addListener(_onAchievementsChanged);

      final location =
          Provider.of<UserLocationProvider>(context, listen: false);
      // Seed the streak state from the current value. This both
      // sets [_lastSeenStreak] and pre-marks every threshold
      // already crossed as prompted, so a returning user with
      // a 14-day streak doesn't get hit with three snackbars
      // the moment they open the app.
      _lastSeenStreak = location.currentStreakDays;
      for (final t in kStreakShareMilestones) {
        if (_lastSeenStreak >= t) _streakThresholdsPrompted.add(t);
      }
      location.addListener(_onLocationChanged);
    });
  }

  @override
  void dispose() {
    // Defensive: only remove if we successfully attached in initState.
    try {
      Provider.of<AchievementProvider>(context, listen: false)
          .removeListener(_onAchievementsChanged);
      Provider.of<UserLocationProvider>(context, listen: false)
          .removeListener(_onLocationChanged);
    } catch (_) {
      // Provider may already be gone if the tree is being torn down.
    }
    super.dispose();
  }

  void _onAchievementsChanged() {
    if (!mounted) return;
    final achievements =
        Provider.of<AchievementProvider>(context, listen: false);
    final newOnes = newlyUnlockedBetween(
      _lastSeenUnlocked,
      achievements.unlockedAchievements,
    );
    _lastSeenUnlocked = List<String>.from(achievements.unlockedAchievements);
    if (newOnes.isNotEmpty) {
      // Pass the full list, not one at a time: each per-title
      // snackbar used to call clearSnackBars() at entry, so a
      // multi-threshold jump (e.g. world% 0 -> 25% unlocking
      // Walker + Pioneer + Traveller) used to only show the last
      // one. Now we show all of them in a single snackbar.
      _showCelebrationSnackBar(newOnes);
    }
  }

  /// Fires on every UserLocationProvider notification. Detects
  /// the moment the user's current streak *increases* past a
  /// [kStreakShareMilestones] threshold and shows a one-shot
  /// "Share your streak?" snackbar with an action that opens
  /// the share dialog pre-loaded with the streak brag. The
  /// seed-and-track pattern in initState means a returning
  /// user with an existing 14-day streak doesn't get spammed
  /// on every app open.
  void _onLocationChanged() {
    if (!mounted) return;
    final location = Provider.of<UserLocationProvider>(context, listen: false);
    final newStreak = location.currentStreakDays;
    // No increase —nothing to do. (Streak decreasing or staying
    // flat both fall through; only crossings upward trigger a
    // prompt.)
    if (newStreak <= _lastSeenStreak) {
      _lastSeenStreak = newStreak;
      return;
    }
    _lastSeenStreak = newStreak;

    final milestone = newStreakShareMilestone(
      currentStreak: newStreak,
      alreadyPrompted: _streakThresholdsPrompted,
    );
    if (milestone == null) return;
    _streakThresholdsPrompted.add(milestone);
    _showStreakSharePrompt(milestone);
  }

  /// SnackBar shown when the user crosses a streak-milestone
  /// threshold. Action button opens the share dialog so the
  /// user can post their brag without leaving the map.
  void _showStreakSharePrompt(int days) {
    final l = L10n.of(context);
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 6),
          backgroundColor: Colors.orange.shade700,
          content: Row(
            children: [
              const Icon(Icons.local_fire_department, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$days ${pluralize(days, l.hudDayStreak, l.hudDaysStreak)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: l.shareStreakPrompt,
            textColor: Colors.white,
            onPressed: () {
              if (!mounted) return;
              HamburgerMenu.showShareDialog(context);
            },
          ),
        ),
      );
  }

  /// Recenter the map on the suggestion's target cell. We also
  /// disable auto-recentering so the map doesn't yank itself
  /// back to the user's current location on the next GPS fix —
  /// the user explicitly asked to look at the target, so we
  /// respect that. The bottom-right RecenterButton restores
  /// follow-mode when they're done walking.
  void _onSuggestionTap(ExplorationSuggestion s) {
    final provider = Provider.of<UserLocationProvider>(context, listen: false);
    _mapController.move(s.target, provider.currentZoom);
    provider.setRecentered(false);
  }

  /// Initializes the map by fetching the user's location.
  Future<void> _initializeMap() async {
    final l = L10n.of(context);
    try {
      final provider =
          Provider.of<UserLocationProvider>(context, listen: false);
      // Restore any previously-visited cells from disk first so the
      // exploration HUD shows accumulated progress on app start.
      await provider.loadFromStorage();
      // Fetch and update the user's location using the provider
      await provider.updateUserLocation();
      // _initializeMap is called from both initState (no risk)
      // and from the RecenterButton onRecenter callback (real
      // risk: the user may have navigated away during the
      // await). mounted check before any post-await UI work.
      if (!mounted) return;

      // Move the map to the user's location with maximum zoom
      _mapController.move(
          provider.userLocation.coordinates, provider.currentZoom);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      // Same mounted guard in the catch path —if the user
      // navigated away during one of the awaits, we must not
      // touch _isLoading or pop a snackbar against a disposed
      // widget.
      if (!mounted) return;
      // Handle any errors. The prefix is localised; the
      // exception's own toString() stays as-is (typed
      // LocationPermissionDeniedException already routes to the
      // onboarding-permission copy before we ever get here).
      _showSnackBar('${l.mapInitFailed} $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Displays a SnackBar with the given message.
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: CustomText(text: message)),
    );
  }

  /// Celebration snackbar shown when the user unlocks one or more
  /// badges in a single update. Triggers a medium haptic and shows
  /// a green card with a trophy icon, so the moment feels
  /// distinctly different from a regular info snackbar.
  ///
  /// Takes a list because multi-threshold jumps are real (e.g. a
  /// fresh user whose first fix lands them in a 25% world cell
  /// unlocks Walker + Pioneer + Traveller at once). The previous
  /// single-title version used clearSnackBars() per call, so only
  /// the last title ever showed.
  void _showCelebrationSnackBar(List<String> titles) {
    final l = L10n.of(context);
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 3),
          content: Row(
            children: [
              Icon(Icons.emoji_events,
                  color: Colors.white, semanticLabel: l.badgeSemanticLabel),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      L10n.of(context).badgeUnlockHeader,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    // Show each newly-unlocked title on its own line.
                    // For multi-threshold jumps (e.g. fresh user
                    // jumping world% 0 -> 25% and unlocking Walker +
                    // Pioneer + Traveller in one fix) we list all
                    // and append a '+ N more' footer so the user
                    // sees them all without the snackbar getting
                    // too tall.
                    for (final t in titles)
                      Text(
                        t,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    if (titles.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '+ ${titles.length - 1} more',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final userLocationProvider = Provider.of<UserLocationProvider>(context);
    final l = L10n.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l.appTitle,
          style: AppTextStyles.appBarTitle,
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
      ),
      drawer: const HamburgerMenu(),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Colors.green),
                  const SizedBox(height: 16),
                  Text(
                    L10n.of(context).findingLocation,
                    style: const TextStyle(
                      fontFamily: 'PixelFont',
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                // Map Layer
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter:
                        userLocationProvider.userLocation.coordinates,
                    initialZoom: userLocationProvider.currentZoom,
                    maxZoom: 30.0, // Set maximum zoom level
                    onPositionChanged: (position, bool hasGesture) {
                      if (hasGesture) {
                        // User interacted with the map, disable auto-centering
                        userLocationProvider.setRecentered(false);
                      }

                      // If auto-centering is enabled, keep the map centered on the user
                      if (userLocationProvider.isRecentered) {
                        // Calculate the distance between current map center and user location
                        final distance = Distance().as(
                          LengthUnit.Meter,
                          position.center,
                          userLocationProvider.userLocation.coordinates,
                        );

                        // If the distance is greater than a small threshold, recenter the map
                        if (distance > 10) {
                          // Threshold in meters
                          _mapController.move(
                            userLocationProvider.userLocation.coordinates,
                            userLocationProvider.currentZoom,
                            // Prevents triggering onPositionChanged again
                            // animate: false, // Uncomment if animate is necessary
                          );
                        }
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                      subdomains: ['a', 'b', 'c'],
                      additionalOptions: {
                        'user_agent': 'UrbixHK/1.0.0',
                      },
                    ),
                    // Visited-cell footprint: one green dot per distinct
                    // geohash-5 cell the user has entered this session.
                    // ExcludeSemantics because a screen reader would
                    // otherwise enumerate every circle one by one;
                    // the HUD already carries the count + distance +
                    // day stats, which is the meaningful summary.
                    ExcludeSemantics(
                      child: CircleLayer(
                        circles: userLocationProvider.visitedCellLocations
                            .map((point) => CircleMarker(
                                  point: point,
                                  // geohash-5 cells are ~1.2 km wide at HK
                                  // latitude (see lib/utils/geohash.dart).
                                  // Render at 600 m so adjacent cells overlap
                                  // visibly without dominating the map at
                                  // city zoom.
                                  radius: 600,
                                  useRadiusInMeter: true,
                                  color: Colors.green.withOpacity(0.25),
                                  borderColor: Colors.green,
                                  borderStrokeWidth: 1,
                                ))
                            .toList(),
                      ),
                    ),
                    // User Location Marker with Custom Image. Wrapped
                    // in Semantics so a screen-reader user hears "You
                    // are here" rather than a bare image announcement.
                    Semantics(
                      label: l.youAreHere,
                      child: MarkerLayer(
                        markers: [
                          Marker(
                            width: 80.0,
                            height: 80.0,
                            point:
                                userLocationProvider.userLocation.coordinates,
                            child: Image.asset(
                              'assets/img/user_m.png',
                              width: 40,
                              height: 40,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Positioned UI Elements: a single compact HUD card
                // (replaces the old 5-row wall of text). One headline
                // percent + a secondary row of small-icon stats.
                Positioned(
                  top: 20,
                  left: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '${userLocationProvider.worldPercentage}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'PixelFont',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              L10n.of(context).hudExplored,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.75),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _hudStat(
                              icon: Icons.straighten,
                              label: formatDistance(
                                  userLocationProvider.totalDistanceMeters),
                            ),
                            const SizedBox(width: 14),
                            _hudStat(
                              icon: Icons.calendar_today,
                              label: '${userLocationProvider.daysExplored}d',
                            ),
                            const SizedBox(width: 14),
                            _hudStat(
                              icon: Icons.grid_on,
                              label:
                                  '${userLocationProvider.uniqueCellsVisited}',
                            ),
                          ],
                        ),
                        if (userLocationProvider.currentDistrictName !=
                            null) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on,
                                  color: Colors.white70, size: 14),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  userLocationProvider.currentDistrictName!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (userLocationProvider.cellsInCurrentDistrict >
                                  0) ...[
                                const SizedBox(width: 6),
                                Builder(builder: (context) {
                                  final l = L10n.of(context);
                                  final n = userLocationProvider
                                      .cellsInCurrentDistrict;
                                  return Text(
                                    '蝜?$n ${n == 1 ? l.hudVisit : l.hudVisits}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.75),
                                      fontSize: 12,
                                    ),
                                  );
                                }),
                              ],
                            ],
                          ),
                          // Next-milestone progress: shown only
                          // when there is at least one un-unlocked
                          // achievement. Gives the user a goal with
                          // a visible bar showing how close they are
                          // (filled to the tier color so harder
                          // milestones read differently at a glance).
                          Builder(builder: (context) {
                            final l = L10n.of(context);
                            final next = context
                                .watch<AchievementProvider>()
                                .nextAchievement();
                            if (next == null) return const SizedBox.shrink();
                            // Anchor the bar at the previously-unlocked
                            // threshold (or 0) so the visible fill
                            // matches "how much of the way to next".
                            final previousThreshold =
                                _previousUnlockedThreshold(
                                    context.read<AchievementProvider>(),
                                    next.threshold);
                            final span = (next.threshold - previousThreshold)
                                .clamp(1, 100);
                            final filledSoFar = (context
                                        .read<UserLocationProvider>()
                                        .worldPercentage -
                                    previousThreshold)
                                .clamp(0, span);
                            final progress = filledSoFar / span;
                            final tierColor = _tierColorForThreshold(
                                tierForThreshold(next.threshold));
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Flexible + ellipsis because the
                                  // "Are you sure you're not cheating?"
                                  // milestone title is ~32 chars and
                                  // pushes the chip wider than the
                                  // HUD card on narrow phones.
                                  Flexible(
                                    child: Text(
                                      '${l.hudNextMilestone}: ${next.title} @ ${next.threshold}% 蝜?${next.cellsToGo} ${l.hudCellsToGo}',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.85),
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 6,
                                      backgroundColor: Colors.white24,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          tierColor),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          // Today's distance: only shown when the
                          // user has actually moved today. Hidden on
                          // a fresh day (0 m) so the HUD doesn't
                          // show a meaningless "0 m" line.
                          if (userLocationProvider.todayDistanceMeters > 0) ...[
                            Builder(builder: (context) {
                              final l = L10n.of(context);
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  '${l.hudToday}: ${formatDistance(userLocationProvider.todayDistanceMeters)}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            }),
                          ],
                          // Streak chip: shown only when the user
                          // has a current streak of 2+ days. A
                          // single-day streak is just 'today', which
                          // is already implicit in the data; we
                          // reserve the chip for the more
                          // interesting case of an actual streak.
                          if (userLocationProvider.currentStreakDays >= 2) ...[
                            Builder(builder: (context) {
                              final l = L10n.of(context);
                              final s = userLocationProvider.currentStreakDays;
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.local_fire_department,
                                        color: Colors.orange, size: 14),
                                    const SizedBox(width: 4),
                                    // Flexible so a very large streak
                                    // (e.g. 9999 days) doesn't push
                                    // the share icon off the HUD on
                                    // narrow screens. softWrap is left
                                    // off because the chip should stay
                                    // one line; the worst case is a
                                    // mid-word ellipsis, which is
                                    // preferable to a layout overflow
                                    // stripe.
                                    Flexible(
                                      child: Text(
                                        '${l.hudStreak}: $s ${pluralize(s, l.hudDayStreak, l.hudDaysStreak)}',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.85),
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    // Visible share affordance: a
                                    // small share icon right next
                                    // to the streak chip, shown
                                    // once the streak is brag-
                                    // worthy (>= 3 days). Tapping
                                    // opens the share dialog
                                    // pre-loaded with the streak
                                    // brag. The auto-prompt
                                    // snackbar (FEAT-5) brings
                                    // this to the user's
                                    // attention; this icon keeps
                                    // it one tap away afterwards.
                                    if (s >= 3) ...[
                                      const SizedBox(width: 8),
                                      Builder(builder: (innerContext) {
                                        final l2 = L10n.of(innerContext);
                                        return Tooltip(
                                          // Tooltip on long-press so
                                          // TalkBack also reads the
                                          // share-button purpose aloud
                                          // (the bare ios_share icon
                                          // has no semantic label).
                                          message: l2.shareStreakPrompt,
                                          child: InkWell(
                                            onTap: () => HamburgerMenu
                                                .showShareDialog(context),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: const Padding(
                                              padding: EdgeInsets.all(2),
                                              child: Icon(Icons.ios_share,
                                                  color: Colors.white,
                                                  size: 14),
                                            ),
                                          ),
                                        );
                                      }),
                                    ],
                                  ],
                                ),
                              );
                            }),
                          ],
                        ],
                        // "Next" chip: the top-ranked suggestion
                        // from the exploration-suggestion engine.
                        // Lives outside the currentDistrictName
                        // guard so it still appears for users who
                        // are at sea or in a part of HK that the
                        // bounding boxes don't cover (the engine
                        // ranks candidates by proximity, the
                        // district name is just the label).
                        if (userLocationProvider.currentSuggestion != null) ...[
                          Builder(builder: (context) {
                            final l = L10n.of(context);
                            final s = userLocationProvider.currentSuggestion!;
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: InkWell(
                                onTap: () => _onSuggestionTap(s),
                                borderRadius: BorderRadius.circular(12),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.explore,
                                        color: Colors.greenAccent, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${l.suggestionChip}: '
                                      '${s.districtName ?? l.suggestionExploreOther}'
                                      ' 蝜?${formatDistance(s.distanceFromUserMeters)}',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.85),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ),
                // First-run hint: only shown until the user has visited
                // at least one new cell. Explains the green-circle
                // mechanic without burying the rest of the UI under a
                // permanent legend.
                if (userLocationProvider.uniqueCellsVisited == 0)
                  Positioned(
                    top: 24,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 280),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.directions_walk,
                                color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                L10n.of(context).firstRunHint,
                                style: const TextStyle(
                                  fontFamily: 'PixelFont',
                                  fontSize: 12,
                                  color: Colors.black87,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                // Recenter Button
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: RecenterButton(
                    mapController: _mapController,
                    onRecenter: _initializeMap,
                  ),
                ),
              ],
            ),
    );
  }
}

/// Compact icon + label pair used in the map HUD's secondary row.
Widget _hudStat({required IconData icon, required String label}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: Colors.white70, size: 14),
      const SizedBox(width: 4),
      Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}

/// The highest threshold the user has already passed, or 0 if none.
/// Used to anchor the next-milestone progress bar at the right
/// start point (so the fill really represents progress toward the
/// next goal, not progress since world=0).
int _previousUnlockedThreshold(
    AchievementProvider provider, int nextThreshold) {
  int prev = 0;
  for (final e in provider.achievementThresholds.entries) {
    if (e.value < nextThreshold && provider.isUnlocked(e.key)) {
      prev = e.value;
    }
  }
  return prev;
}

/// Map a world-% threshold to the muted tier color used by the
/// achievement/medal screens. Kept local to the map screen so the
/// bar reads as part of the HUD's visual language.
Color _tierColorForThreshold(AchievementTier tier) {
  switch (tier) {
    case AchievementTier.gold:
      return const Color(0xFFD4A017);
    case AchievementTier.silver:
      return const Color(0xFF8E96A1);
    case AchievementTier.bronze:
      return const Color(0xFFB87333);
  }
}

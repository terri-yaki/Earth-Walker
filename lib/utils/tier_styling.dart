// lib/utils/tier_styling.dart
//
// Shared visual + label helpers for [AchievementTier]. Both the
// Achievement screen and the Medal screen render tier-coloured
// badges next to each unlocked item, and they previously carried
// identical `_tierColor` / `_tierLabel` private methods. Centralising
// the mapping here keeps the colour palette and label keys in one
// place: change a tier's hex code once and both screens pick it
// up, and there's no risk of one screen drifting from the other
// (e.g. bronze on one side, gold on the other).

import 'package:flutter/material.dart';

import '../providers/achievement_provider.dart' show AchievementTier;
import 'l10n.dart';

/// Colour for a tier's badge / icon. Picked muted (not the
/// bright primary versions) so the unlocked icons read as
/// "achievement" rather than "warning yellow" on the white
/// scaffold.
Color tierColor(AchievementTier tier) {
  switch (tier) {
    case AchievementTier.gold:
      return const Color(0xFFD4A017); // muted gold
    case AchievementTier.silver:
      return const Color(0xFF8E96A1); // muted silver
    case AchievementTier.bronze:
      return const Color(0xFFB87333); // muted bronze / copper
  }
}

/// Localised short label for a tier ('GOLD' / '金', etc.). The
/// label is rendered as a small inline chip next to the
/// unlocked title, so the caller passes the live [L10n]
/// (lookup must happen inside a BuildContext).
String tierLabel(AchievementTier tier, L10n l) {
  switch (tier) {
    case AchievementTier.gold:
      return l.tierGold;
    case AchievementTier.silver:
      return l.tierSilver;
    case AchievementTier.bronze:
      return l.tierBronze;
  }
}

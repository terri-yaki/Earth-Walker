// lib/utils/l10n.dart
//
// Bilingual localisation. Two locales:
//   en     - English (default)
//   zh-HK  - Traditional Chinese, as used in Hong Kong
//
// Translation strings live in assets/l10n/{en,zh-HK}.json so
// non-coders can edit translations without touching Dart. The
// L10n class itself is a pure data carrier; the L10nDelegate
// does the asset I/O at startup. Tests construct L10n directly
// with explicit string maps, so they don't need any rootBundle
// setup.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Supported locales, in preference order. Matches the values in
/// supportedLocales on MaterialApp.
const List<Locale> kSupportedLocales = <Locale>[
  Locale('en'),
  Locale('zh', 'HK'),
];

/// Returns the closest supported [Locale] for [deviceLocale], or
/// the first entry in [kSupportedLocales] as a fallback. Used by
/// [L10nDelegate].
Locale resolveLocale(Locale? deviceLocale) {
  if (deviceLocale == null) return kSupportedLocales.first;
  // Exact match?
  for (final l in kSupportedLocales) {
    if (l.languageCode == deviceLocale.languageCode &&
        l.countryCode == deviceLocale.countryCode) {
      return l;
    }
  }
  // Language-only match?
  for (final l in kSupportedLocales) {
    if (l.languageCode == deviceLocale.languageCode) return l;
  }
  return kSupportedLocales.first;
}

/// Pure-data localisation class. The per-locale strings are
/// passed in by [L10nDelegate.load] (production) or directly by
/// tests. The fallback for any missing key is the [fallback]
/// table (typically the English table) so adding a new key
/// without translating it is safe.
class L10n {
  final Locale locale;
  final Map<String, String> _strings;
  final Map<String, String> _fallback;

  L10n(this.locale, Map<String, String> strings,
      [Map<String, String>? fallback])
      : _strings = Map.unmodifiable(strings),
        _fallback = Map.unmodifiable(fallback ?? const {});

  /// Look up the [L10n] instance for [context], which must be inside
  /// a [MaterialApp] that has the [L10nDelegate] registered. Falls
  /// back to a stub English L10n if the lookup fails, so a missing
  /// delegate (e.g. in a unit test) doesn't crash ??it just renders
  /// the raw key string.
  static L10n of(BuildContext context) {
    final l = Localizations.of<L10n>(context, L10n);
    return l ?? L10n(const Locale('en'), const {});
  }

  String _lookup(String key) => _strings[key] ?? _fallback[key] ?? key;

  String get appTitle => _lookup('app_title');
  String get menuAchievements => _lookup('menu_achievements');
  String get menuMedals => _lookup('menu_medals');
  String get menuDistricts => _lookup('menu_districts');
  String get menuReset => _lookup('menu_reset');
  String get menuShare => _lookup('menu_share');
  String get menuCompare => _lookup('menu_compare');
  String get resetDialogTitle => _lookup('reset_dialog_title');
  String get resetDialogBody => _lookup('reset_dialog_body');
  String get resetDialogConfirm => _lookup('reset_dialog_confirm');
  String get resetDialogCancel => _lookup('reset_dialog_cancel');
  String get resetDialogCopy => _lookup('reset_dialog_copy');
  String get shareDialogTitle => _lookup('share_dialog_title');
  String get shareDialogCopy => _lookup('share_dialog_copy');
  String get shareDialogCopied => _lookup('share_dialog_copied');
  String get shareDialogShare => _lookup('share_dialog_share');
  String get shareDialogShared => _lookup('share_dialog_shared');
  String get shareBragDefault => _lookup('share_brag_default');
  String get shareBragStreak => _lookup('share_brag_streak');
  String get shareStreakPrompt => _lookup('share_streak_prompt');
  String get compareDialogTitle => _lookup('compare_dialog_title');
  String get compareDialogPasteHint => _lookup('compare_dialog_paste_hint');
  String get compareDialogCompare => _lookup('compare_dialog_compare');
  String get compareDialogYou => _lookup('compare_dialog_you');
  String get compareDialogThem => _lookup('compare_dialog_them');
  String get compareDialogClose => _lookup('compare_dialog_close');
  String get compareDialogYouWin => _lookup('compare_dialog_you_win');
  String get compareDialogTheyWin => _lookup('compare_dialog_they_win');
  String get compareDialogYouTie => _lookup('compare_dialog_you_tie');
  String get compareDialogParseFailed => _lookup('compare_dialog_parse_failed');
  String get compareDialogTied => _lookup('compare_dialog_tied');
  String get progressCopied => _lookup('progress_copied');
  String get progressResetDone => _lookup('progress_reset_done');
  String get findingLocation => _lookup('finding_location');
  String get firstRunHint => _lookup('first_run_hint');
  String get hudExplored => _lookup('hud_explored');
  String get hudVisit => _lookup('hud_visit');
  String get hudVisits => _lookup('hud_visits');
  String get hudToday => _lookup('hud_today');
  String get hudStreak => _lookup('hud_streak');
  String get hudDayStreak => _lookup('hud_day_streak');
  String get hudDaysStreak => _lookup('hud_days_streak');
  String get hudNextMilestone => _lookup('hud_next_milestone');
  String get hudCellsToGo => _lookup('hud_cells_to_go');
  String get screenAchievements => _lookup('screen_achievements');
  String get screenMedals => _lookup('screen_medals');
  String get screenDistricts => _lookup('screen_districts');
  String get onboardingPitch => _lookup('onboarding_pitch');
  String get onboardingGetStarted => _lookup('onboarding_get_started');
  String get onboardingLocOff => _lookup('onboarding_loc_off');
  String get onboardingPermDenied => _lookup('onboarding_perm_denied');
  String get onboardingPermDeniedForever =>
      _lookup('onboarding_perm_denied_forever');
  String get onboardingLocErrorPrefix => _lookup('onboarding_loc_error_prefix');
  String get badgesHeader => _lookup('badges_header');
  String get badgesEmpty => _lookup('badges_empty');
  String get badgeUnlockedAt => _lookup('badge_unlocked_at');
  String get medalsEarned => _lookup('medals_earned');
  String get medalsAwardedAt => _lookup('medals_awarded_at');
  String get cellSingular => _lookup('cell_singular');
  String get cellPlural => _lookup('cell_plural');
  String get districtsExplored => _lookup('districts_explored');
  String get badgeUnlockHeader => _lookup('badge_unlock_header');
  String get suggestionChip => _lookup('suggestion_chip');
  String get suggestionExploreOther => _lookup('suggestion_explore_other');

  /// Lookup for any key not covered by a typed getter. Useful in
  /// tests; production code should prefer the typed getters.
  @visibleForTesting
  String lookup(String key) => _lookup(key);
}

/// Localisations delegate. Looks up the closest supported locale,
/// loads the JSON file for it from rootBundle, and falls back to
/// English for any missing key.
class L10nDelegate extends LocalizationsDelegate<L10n> {
  const L10nDelegate();

  @override
  bool isSupported(Locale locale) =>
      kSupportedLocales.any((l) => l.languageCode == locale.languageCode);

  @override
  Future<L10n> load(Locale locale) async {
    final resolved = resolveLocale(locale);
    final tag = resolved.toLanguageTag(); // 'en' or 'zh-HK'
    final strings = await _loadTag(tag);
    final fallback = await _loadTag('en');
    return L10n(resolved, strings, fallback);
  }

  /// Try to load assets/l10n/<tag>.json. Returns an empty map on any
  /// failure (corrupt JSON, missing file, asset not bundled) so the
  /// app still runs ??the user just sees the key string instead of
  /// the localised copy.
  Future<Map<String, String>> _loadTag(String tag) async {
    try {
      final raw = await rootBundle.loadString('assets/l10n/$tag.json');
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return <String, String>{};
      return decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
    } catch (_) {
      return <String, String>{};
    }
  }

  @override
  bool shouldReload(L10nDelegate old) => false;
}


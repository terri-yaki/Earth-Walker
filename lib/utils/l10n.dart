// lib/utils/l10n.dart
//
// Manual localisation. Two locales:
//   en     - English (default)
//   zh-HK  - Traditional Chinese, as used in Hong Kong
//
// Hand-written instead of using flutter_localizations + .arb
// codegen so the project has no generated files and no extra
// `flutter gen-l10n` build step — the strings live here, the
// translations live here, and the test exercises both.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Supported locales, in preference order. Matches the values in
/// supportedLocales on MaterialApp.
const List<Locale> kSupportedLocales = <Locale>[
  Locale('en'),
  Locale('zh', 'HK'),
];

/// Returns the closest supported [Locale] for [deviceLocale], or
/// the first entry in [kSupportedLocales] as a fallback. Used by
/// [L10nDelegate.isSupported.
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

/// Per-locale string table. The fallback for any missing key is
/// the English value, so adding a new key without translating it
/// to zh-HK is safe — the user just sees English.
class L10n {
  final Locale locale;
  L10n(this.locale);

  /// Look up the [L10n] instance for [context], which must be inside
  /// a [MaterialApp] that has the [L10nDelegate] registered. Falls
  /// back to the English L10n if the lookup fails, so a missing
  /// delegate (e.g. in a unit test) doesn't crash — it just renders
  /// English.
  static L10n of(BuildContext context) {
    final l = Localizations.of<L10n>(context, L10n);
    return l ?? L10n(const Locale('en'));
  }

  static const Map<String, Map<String, String>> _table = {
    'en': {
      'app_title': 'Urbix HK',
      'menu_achievements': 'Achievements',
      'menu_medals': 'Medals',
      'menu_districts': 'Districts',
      'menu_reset': 'Reset Progress',
      'reset_dialog_title': 'Reset progress?',
      'reset_dialog_confirm': 'Reset',
      'reset_dialog_cancel': 'Cancel',
      'reset_dialog_copy': 'Copy',
      'progress_copied': 'Progress copied to clipboard.',
      'progress_reset_done': 'Progress reset.',
      'finding_location': 'Finding your location…',
      'first_run_hint':
          'Walk around to discover new places. Visited areas appear as green circles.',
      'hud_explored': 'explored',
      'hud_visit': 'visit',
      'hud_visits': 'visits',
    },
    'zh-HK': {
      'app_title': 'Urbix 香港',
      'menu_achievements': '成就',
      'menu_medals': '獎牌',
      'menu_districts': '地區',
      'menu_reset': '重設進度',
      'reset_dialog_title': '確定要重設進度？',
      'reset_dialog_confirm': '重設',
      'reset_dialog_cancel': '取消',
      'reset_dialog_copy': '複製',
      'progress_copied': '已複製進度至剪貼簿。',
      'progress_reset_done': '已重設進度。',
      'finding_location': '正在定位…',
      'first_run_hint':
          '周圍行吓啦，探索新地方。已到訪嘅範圍會以綠圈顯示。',
      'hud_explored': '已探索',
      'hud_visit': '次到訪',
      'hud_visits': '次到訪',
    },
  };

  String _lookup(String key) {
    final byLocale = _table[locale.toLanguageTag().replaceAll('-', '_')] ??
        // dart:ui's Locale#toLanguageTag uses hyphens, our table
        // uses underscores for zh-Hant / zh-HK style — try both.
        _table[locale.toString()] ??
        _table['en']!;
    return byLocale[key] ?? _table['en']![key] ?? key;
  }

  String get appTitle => _lookup('app_title');
  String get menuAchievements => _lookup('menu_achievements');
  String get menuMedals => _lookup('menu_medals');
  String get menuDistricts => _lookup('menu_districts');
  String get menuReset => _lookup('menu_reset');
  String get resetDialogTitle => _lookup('reset_dialog_title');
  String get resetDialogConfirm => _lookup('reset_dialog_confirm');
  String get resetDialogCancel => _lookup('reset_dialog_cancel');
  String get resetDialogCopy => _lookup('reset_dialog_copy');
  String get progressCopied => _lookup('progress_copied');
  String get progressResetDone => _lookup('progress_reset_done');
  String get findingLocation => _lookup('finding_location');
  String get firstRunHint => _lookup('first_run_hint');
  String get hudExplored => _lookup('hud_explored');
  String get hudVisit => _lookup('hud_visit');
  String get hudVisits => _lookup('hud_visits');

  /// Lookup for any key not covered by a typed getter. Useful in
  /// tests; production code should prefer the typed getters.
  @visibleForTesting
  String lookup(String key) => _lookup(key);
}

class L10nDelegate extends LocalizationsDelegate<L10n> {
  const L10nDelegate();

  @override
  bool isSupported(Locale locale) =>
      kSupportedLocales.any((l) => l.languageCode == locale.languageCode);

  @override
  Future<L10n> load(Locale locale) async {
    return L10n(resolveLocale(locale));
  }

  @override
  bool shouldReload(L10nDelegate old) => false;
}

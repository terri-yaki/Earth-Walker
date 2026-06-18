import 'package:flutter_test/flutter_test.dart';
import 'package:urbix/utils/l10n.dart';

/// Inlined test strings. Mirrors assets/l10n/{en,zh-HK}.json but
/// without the JSON I/O so unit tests don't need a rootBundle
/// binding. The provider in the asset file is the source of
/// truth; if a new key is added there, it should be added here
/// too.
const Map<String, String> _enStrings = <String, String>{
  'app_title': 'Urbix HK',
  'menu_achievements': 'Achievements',
  'menu_medals': 'Medals',
  'menu_districts': 'Districts',
  'menu_reset': 'Reset Progress',
  'menu_share': 'Share Progress',
  'reset_dialog_title': 'Reset progress?',
  'reset_dialog_body': 'This will permanently clear your exploration history.',
  'reset_dialog_confirm': 'Reset',
  'reset_dialog_cancel': 'Cancel',
  'reset_dialog_copy': 'Copy',
  'share_dialog_title': 'Share your progress',
  'share_dialog_copy': 'Copy',
  'share_dialog_copied': 'Progress copied. Send it to a friend!',
  'share_dialog_share': 'Share',
  'share_dialog_shared': 'Thanks for spreading the word!',
  'share_brag_default': "I've been exploring Hong Kong with Urbix HK.",
  'share_brag_streak': "On a roll with Urbix HK \u2014 can you beat my streak?",
  'share_streak_prompt': 'Share your streak?',
  'menu_compare': 'Compare with friend',
  'compare_dialog_title': 'Compare with a friend',
  'compare_dialog_paste_hint': "Paste your friend's snapshot here",
  'compare_dialog_compare': 'Compare',
  'compare_dialog_you': 'You',
  'compare_dialog_them': 'Them',
  'compare_dialog_close': 'Close',
  'compare_dialog_you_win': 'You win',
  'compare_dialog_they_win': 'They win',
  'compare_dialog_you_tie': 'tied',
  'compare_dialog_parse_failed': "That doesn't look like a Urbix HK snapshot.",
  'compare_dialog_tied': "You're tied on every metric!",
  'progress_copied': 'Progress copied to clipboard.',
  'progress_reset_done': 'Progress reset.',
  'finding_location': 'Finding your location\u2026',
  'first_run_hint':
      'Walk around to discover new places. Visited areas appear as green circles.',
  'hud_explored': 'explored',
  'hud_visit': 'visit',
  'hud_visits': 'visits',
  'hud_today': 'Today',
  'hud_streak': 'Streak',
  'hud_day_streak': 'day streak',
  'hud_days_streak': 'day streak',
  'hud_next_milestone': 'Next',
  'hud_cells_to_go': 'to go',
  'screen_achievements': 'Achievements',
  'screen_medals': 'Medals',
  'screen_districts': 'Districts',
  'onboarding_pitch':
      'Walk your city. Unlock badges as you explore new neighbourhoods.',
  'onboarding_get_started': 'Get Started',
  'onboarding_loc_off':
      'Location services are off. Please turn them on in Settings, then come back.',
  'onboarding_perm_denied':
      'Urbix HK needs your location to track where you explore. Please allow it and try again.',
  'onboarding_perm_denied_forever':
      'Location permission is permanently denied. Enable it in Settings to use Urbix HK.',
  'onboarding_loc_error_prefix': 'Could not request location:',
  'badges_header': 'Badges',
  'badges_empty': 'No badges yet. Keep exploring to unlock your first one!',
  'badge_unlocked_at': 'Unlocked at',
  'medals_earned': 'earned',
  'medals_awarded_at': 'Awarded at',
  'cell_singular': 'cell',
  'cell_plural': 'cells',
  'districts_explored': 'districts explored',
  'badge_unlock_header': 'Badge unlocked!',
  'suggestion_chip': 'Next',
  'suggestion_explore_other': 'a new area',
};

const Map<String, String> _zhStrings = <String, String>{
  'app_title': 'Urbix \u9999\u6e2f',
  'menu_achievements': '\u6210\u5c31',
  'menu_medals': '\u734e\u724c',
  'menu_districts': '\u5730\u5340',
  'menu_reset': '\u91cd\u8a2d\u9032\u5ea6',
  'menu_share': '\u5206\u4eab\u9032\u5ea6',
  'reset_dialog_title': '\u78ba\u5b9a\u8981\u91cd\u8a2d\u9032\u5ea6\uff1f',
  'reset_dialog_body':
      '\u5c07\u6703\u6c38\u4e45\u6e05\u9664\u4f60\u6240\u6709\u63a2\u7d22\u7d00\u9304\u3002',
  'reset_dialog_confirm': '\u91cd\u8a2d',
  'reset_dialog_cancel': '\u53d6\u6d88',
  'reset_dialog_copy': '\u8907\u88fd',
  'share_dialog_title': '\u5206\u4eab\u4f60\u7684\u9032\u5ea6',
  'share_dialog_copy': '\u8907\u88fd',
  'share_dialog_copied':
      '\u5df2\u8907\u88fd\u3002\u50b3\u7d66\u670b\u53cb\u5566\uff01',
  'share_dialog_share': '\u5206\u4eab',
  'share_dialog_shared': '\u591a\u8b1d\u4f60\u5e6b\u5fd9\u5ba3\u50b3\uff01',
  'share_brag_default':
      '\u6211\u7528 Urbix \u9999\u6e2f\u63a2\u7d22\u7dca\u5168\u57ce\u3002',
  'share_brag_streak':
      '\u7528 Urbix \u9999\u6e2f keep \u4f4f\u884c\u2014\u2014\u4f60\u63a5\u4e0d\u63a5\u5230\u6211\u7684 streak\uff1f',
  'share_streak_prompt': '\u5206\u4eab\u4f60\u7684 streak\uff1f',
  'menu_compare': '\u8207\u670b\u53cb\u6bd4\u8f03',
  'compare_dialog_title': '\u8207\u670b\u53cb\u6bd4\u8f03',
  'compare_dialog_paste_hint':
      '\u8cbc\u4e0a\u4f60\u670b\u53cb\u7684\u5feb\u7167',
  'compare_dialog_compare': '\u6bd4\u8f03',
  'compare_dialog_you': '\u4f60',
  'compare_dialog_them': '\u4ed6\u5011',
  'compare_dialog_close': '\u95dc\u9589',
  'compare_dialog_you_win': '\u4f60\u8d0f\u54aa',
  'compare_dialog_they_win': '\u4ed6\u5011\u8d0f\u54aa',
  'compare_dialog_you_tie': '\u6253\u548c',
  'compare_dialog_parse_failed':
      '\u770b\u843d\u4e0d\u4f3c Urbix \u9999\u6e2f\u7684\u5feb\u7167\u3002',
  'compare_dialog_tied': '\u6bcf\u9805\u6307\u6a19\u90fd\u6253\u548c\uff01',
  'progress_copied':
      '\u5df2\u8907\u88fd\u9032\u5ea6\u81f3\u526a\u8cbc\u7c3f\u3002',
  'progress_reset_done': '\u5df2\u91cd\u8a2d\u9032\u5ea6\u3002',
  'finding_location': '\u6b63\u5728\u5b9a\u4f4d\u2026',
  'first_run_hint':
      '\u5468\u570d\u884c\u54aa\u5566\uff0c\u63a2\u7d22\u65b0\u5730\u65b9\u3002\u5df2\u5230\u8a2a\u7684\u7bc4\u570d\u6703\u4ee5\u7da0\u5708\u986f\u793a\u3002',
  'hud_explored': '\u5df2\u63a2\u7d22',
  'hud_visit': '\u6b21\u5230\u8a2a',
  'hud_visits': '\u6b21\u5230\u8a2a',
  'hud_today': '\u4eca\u65e5',
  'hud_streak': '\u9023\u7e8c',
  'hud_day_streak': '\u65e5',
  'hud_days_streak': '\u65e5',
  'hud_next_milestone': '\u4e0b\u4e00\u500b',
  'hud_cells_to_go': '\u4ecd\u5dee',
  'screen_achievements': '\u6210\u5c31',
  'screen_medals': '\u734e\u724c',
  'screen_districts': '\u5730\u5340',
  'onboarding_pitch':
      '\u884c\u52d9\u5168\u57ce\uff0c\u63a2\u7d22\u65b0\u5730\u5340\uff0c\u8d0a\u53d6\u52f3\u7ae0\u3002',
  'onboarding_get_started': '\u958b\u59cb\u4f7f\u7528',
  'onboarding_loc_off':
      '\u5b9a\u4f4d\u670d\u52d9\u672a\u958b\u555f\u3002\u8acb\u5230\u300c\u8a2d\u5b9a\u300d\u958b\u555f\u5f8c\u518d\u8a66\u3002',
  'onboarding_perm_denied':
      'Urbix \u9999\u6e2f\u9700\u8981\u53d6\u5f97\u4f60\u7684\u4f4d\u7f6e\u624d\u53ef\u4ee5\u8a18\u9304\u5230\u8a2a\u904e\u7684\u5730\u65b9\u3002\u8acb\u5141\u8a31\u5f8c\u518d\u8a66\u3002',
  'onboarding_perm_denied_forever':
      '\u5b9a\u4f4d\u6b0a\u9650\u5df2\u88ab\u6c38\u4e45\u62d2\u7d55\u3002\u8acb\u5230\u300c\u8a2d\u5b9a\u300d\u958b\u555f\uff0c\u624d\u53ef\u4ee5\u7528 Urbix \u9999\u6e2f\u3002',
  'onboarding_loc_error_prefix': '\u7121\u6cd5\u53d6\u5f97\u4f4d\u7f6e\uff1a',
  'badges_header': '\u52f3\u7ae0',
  'badges_empty':
      '\u4f60\u9084\u672a\u62ff\u5230\u4efb\u4f55\u52f3\u7ae0\u3002\u7e7c\u7e8c\u63a2\u7d22\uff0c\u7b49\u4f60\u89e3\u9396\u7b2c\u4e00\u500b\uff01',
  'badge_unlocked_at': '\u89e3\u9396\u9580\u6e67',
  'medals_earned': '\u5df2\u7372\u5f97',
  'medals_awarded_at': '\u9812\u767c\u9580\u6e67',
  'cell_singular': '\u683c',
  'cell_plural': '\u683c',
  'districts_explored': '\u500b\u5730\u5340\u5df2\u63a2\u7d22',
  'badge_unlock_header': '\u52f3\u7ae0\u89e3\u9396\uff01',
  'suggestion_chip': '\u4e0b\u4e00\u6b65',
  'suggestion_explore_other': '\u65b0\u5730\u65b9',
};

void main() {
  group('resolveLocale', () {
    test('returns exact match when present', () {
      expect(resolveLocale(const Locale('zh', 'HK')), const Locale('zh', 'HK'));
      expect(resolveLocale(const Locale('en')), const Locale('en'));
    });

    test('falls back to language-only match', () {
      // zh-TW should resolve to zh-HK since we don't ship zh-TW
      // but the language code matches.
      expect(resolveLocale(const Locale('zh', 'TW')), const Locale('zh', 'HK'));
    });

    test('falls back to first supported locale for unknown language', () {
      expect(resolveLocale(const Locale('fr', 'FR')), kSupportedLocales.first);
    });

    test('null device locale -> first supported locale', () {
      expect(resolveLocale(null), kSupportedLocales.first);
    });
  });

  group('L10n', () {
    test('English strings are non-empty and human-readable', () {
      final l = L10n(const Locale('en'), _enStrings, _enStrings);
      expect(l.appTitle, 'Urbix HK');
      expect(l.menuAchievements, 'Achievements');
      expect(l.menuMedals, 'Medals');
      expect(l.menuDistricts, 'Districts');
      expect(l.menuReset, 'Reset Progress');
    });

    test('zh-HK strings are non-empty and contain Chinese characters', () {
      final l = L10n(const Locale('zh', 'HK'), _zhStrings, _enStrings);
      // Spot-check: the menu entries should be Chinese, not English.
      expect(l.menuAchievements, isNot('Achievements'));
      expect(l.menuMedals, isNot('Medals'));
      expect(l.menuDistricts, isNot('Districts'));
      expect(l.menuReset, isNot('Reset Progress'));
      // The Chinese strings should contain CJK Unified Ideographs.
      expect(l.menuAchievements, matches(RegExp(r'[\u4E00-\u9FFF]')));
      expect(l.appTitle, matches(RegExp(r'[\u4E00-\u9FFF]')));
    });

    test('onboarding pitch and CTA are localised', () {
      final en = L10n(const Locale('en'), _enStrings, _enStrings);
      final zh = L10n(const Locale('zh', 'HK'), _zhStrings, _enStrings);
      expect(en.onboardingPitch, contains('neighbourhoods'));
      expect(en.onboardingGetStarted, 'Get Started');
      expect(zh.onboardingPitch, matches(RegExp(r'[\u4E00-\u9FFF]')));
      expect(zh.onboardingGetStarted, matches(RegExp(r'[\u4E00-\u9FFF]')));
    });

    test('permission error messages are localised', () {
      final en = L10n(const Locale('en'), _enStrings, _enStrings);
      final zh = L10n(const Locale('zh', 'HK'), _zhStrings, _enStrings);
      expect(en.onboardingPermDenied, contains('location'));
      expect(en.onboardingPermDeniedForever, contains('permanently'));
      expect(en.onboardingLocOff, contains('off'));
      expect(zh.onboardingPermDenied, matches(RegExp(r'[\u4E00-\u9FFF]')));
      expect(
          zh.onboardingPermDeniedForever, matches(RegExp(r'[\u4E00-\u9FFF]')));
    });

    test('badge / medal / district copy is localised', () {
      final en = L10n(const Locale('en'), _enStrings, _enStrings);
      final zh = L10n(const Locale('zh', 'HK'), _zhStrings, _enStrings);
      expect(en.badgesHeader, 'Badges');
      expect(en.medalsEarned, 'earned');
      expect(en.cellSingular, 'cell');
      expect(en.cellPlural, 'cells');
      expect(en.districtsExplored, 'districts explored');
      expect(en.badgeUnlockHeader, 'Badge unlocked!');
      expect(en.medalsAwardedAt, 'Awarded at');
      // zh-HK: every value should carry at least one CJK ideograph.
      for (final s in <String>[
        zh.badgesHeader,
        zh.medalsEarned,
        zh.cellSingular,
        zh.districtsExplored,
        zh.badgeUnlockHeader,
      ]) {
        expect(s, matches(RegExp(r'[\u4E00-\u9FFF]')),
            reason: '$s should contain CJK ideographs');
      }
    });

    test('reset dialog body is localised', () {
      final en = L10n(const Locale('en'), _enStrings, _enStrings);
      final zh = L10n(const Locale('zh', 'HK'), _zhStrings, _enStrings);
      expect(en.resetDialogBody, contains('permanently'));
      expect(en.resetDialogBody, contains('exploration'));
      expect(zh.resetDialogBody, matches(RegExp(r'[\u4E00-\u9FFF]')));
      expect(zh.resetDialogCancel, matches(RegExp(r'[\u4E00-\u9FFF]')));
    });

    test('missing key falls back to English', () {
      // Build a Chinese map that omits the menu_districts key.
      // The L10n class should fall back to _enStrings for that key.
      final zhPartial = <String, String>{
        for (final entry in _zhStrings.entries)
          if (entry.key != 'menu_districts') entry.key: entry.value,
      };
      final l = L10n(const Locale('zh', 'HK'), zhPartial, _enStrings);
      expect(l.menuDistricts, _enStrings['menu_districts']);
      // The present keys should still come from zhPartial.
      expect(l.menuAchievements, _zhStrings['menu_achievements']);
    });
  });
}

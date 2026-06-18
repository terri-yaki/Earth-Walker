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
  'share_brag_streak': "On a roll with Urbix HK ??can you beat my streak?",
  'share_streak_prompt': 'Share your streak?',
  'menu_compare': 'Compare with friend',
  'compare_dialog_title': 'Compare with a friend',
  'compare_dialog_paste_hint': 'Paste your friend\'s snapshot here',
  'compare_dialog_compare': 'Compare',
  'compare_dialog_you': 'You',
  'compare_dialog_them': 'Them',
  'compare_dialog_close': 'Close',
  'compare_dialog_you_win': 'You win',
  'compare_dialog_they_win': 'They win',
  'compare_dialog_you_tie': 'tied',
  'compare_dialog_parse_failed': 'That doesn\'t look like a Urbix HK snapshot.',
  'compare_dialog_tied': 'You\'re tied on every metric!',
  'progress_copied': 'Progress copied to clipboard.',
  'progress_reset_done': 'Progress reset.',
  'finding_location': 'Finding your location??,
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
  'app_title': 'Urbix é¦™æ¸¯',
  'menu_achievements': '?å°±',
  'menu_medals': '?Žç?',
  'menu_districts': '?°å?',
  'menu_reset': '?è¨­?²åº¦',
  'menu_share': '?†äº«?²åº¦',
  'reset_dialog_title': 'ç¢ºå?è¦é?è¨­é€²åº¦ï¼?,
  'reset_dialog_body': 'å°‡æ?æ°¸ä?æ¸…é™¤ä½ æ??‰æŽ¢ç´¢è??„ã€?,
  'reset_dialog_confirm': '?è¨­',
  'reset_dialog_cancel': '?–æ?',
  'reset_dialog_copy': 'è¤‡è£½',
  'share_dialog_title': '?†äº«ä½ å??²åº¦',
  'share_dialog_copy': 'è¤‡è£½',
  'share_dialog_copied': 'å·²è?è£½ã€‚å‚³?€?‹å??¦ï?',
  'share_dialog_share': '?†äº«',
  'share_dialog_shared': 'å¤šè?ä½ å¹«å¿™å®£?³ï?',
  'share_brag_default': '?‘ç”¨ Urbix é¦™æ¸¯?¢ç´¢ç·Šå…¨?Žã€?,
  'share_brag_streak': '??Urbix é¦™æ¸¯ keep ä½è??”â€”ä??¥å??¥åˆ°?‘å? streakï¼?,
  'share_streak_prompt': '?†äº«ä½ å? streakï¼?,
  'menu_compare': '?‡æ??‹æ?è¼?,
  'compare_dialog_title': '?‡æ??‹æ?è¼?,
  'compare_dialog_paste_hint': 'è²¼ä?ä½ æ??‹å?å¿«ç…§',
  'compare_dialog_compare': 'æ¯”è?',
  'compare_dialog_you': 'ä½?,
  'compare_dialog_them': 'ä½¢å?',
  'compare_dialog_close': '?œé?',
  'compare_dialog_you_win': 'ä½ è???,
  'compare_dialog_they_win': 'ä½¢å?è´å?',
  'compare_dialog_you_tie': '?“å?',
  'compare_dialog_parse_failed': '?‡è½?”ä¼¼ Urbix é¦™æ¸¯?…å¿«?§ã€?,
  'compare_dialog_tied': 'æ¯é??‡æ??½æ??Œï?',
  'progress_copied': 'å·²è?è£½é€²åº¦?³å‰ªè²¼ç°¿??,
  'progress_reset_done': 'å·²é?è¨­é€²åº¦??,
  'finding_location': 'æ­?œ¨å®šä???,
  'first_run_hint': '?¨å?è¡Œå??¦ï??¢ç´¢?°åœ°?¹ã€‚å·²?°è¨ª?…ç??æ?ä»¥ç??ˆé¡¯ç¤ºã€?,
  'hud_explored': 'å·²æŽ¢ç´?,
  'hud_visit': 'æ¬¡åˆ°è¨?,
  'hud_visits': 'æ¬¡åˆ°è¨?,
  'hud_today': 'ä»Šæ—¥',
  'hud_streak': '???',
  'hud_day_streak': '??,
  'hud_days_streak': '??,
  'hud_next_milestone': 'ä¸‹ä???,
  'hud_cells_to_go': 'ä»²å·®',
  'screen_achievements': '?å°±',
  'screen_medals': '?Žç?',
  'screen_districts': '?°å?',
  'onboarding_pitch': 'è¡Œå‹»?¨å?ï¼ŒæŽ¢ç´¢æ–°?°å?ï¼Œè³º?–å‹³ç« ã€?,
  'onboarding_get_started': '?‹å?ä½¿ç”¨',
  'onboarding_loc_off': 'å®šä??å??ªé??Ÿã€‚è??°ã€Œè¨­å®šã€é??Ÿå??è©¦??,
  'onboarding_perm_denied': 'Urbix é¦™æ¸¯?€è¦å??–ä??…ä?ç½®å??¯ä»¥è¨˜é??°è¨ª?Žå??°æ–¹?‚è??è¨±å¾Œå?è©¦ã€?,
  'onboarding_perm_denied_forever': 'å®šä?æ¬Šé?å·²è¢«æ°¸ä??’ç??‚è??°ã€Œè¨­å®šã€é??Ÿï??ˆå¯ä»¥ç”¨ Urbix é¦™æ¸¯??,
  'onboarding_loc_error_prefix': '?¡æ??–å?ä½ç½®ï¼?,
  'badges_header': '?³ç?',
  'badges_empty': 'ä½ ä»²?ªæ??°ä»»ä½•å‹³ç« ã€‚ç»§ç»­æŽ¢ç´¢ï?ç­‰ä?è§??ç¬¬ä??‹ï?',
  'badge_unlocked_at': 'è§???€æª?,
  'medals_earned': 'å·²ç²å¾?,
  'medals_awarded_at': '?’ç™¼?€æª?,
  'cell_singular': '??,
  'cell_plural': '??,
  'districts_explored': '?‹åœ°?€å·²æŽ¢ç´?,
  'badge_unlock_header': '?³ç?è§??ï¼?,
  'suggestion_chip': 'ä¸‹ä?æ­?,
  'suggestion_explore_other': '?°åœ°??,
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
    });

    test('missing key falls back to the fallback map, then to the key', () {
      // L10n with one key and no fallback: a hit returns the
      // value, a miss returns the key string.
      final partial = L10n(const Locale('zh', 'HK'), const {'app_title': 'X'});
      expect(partial.appTitle, 'X');
      expect(partial.menuAchievements, 'menu_achievements');
      // Empty L10n with an empty fallback: lookup returns the key.
      final empty = L10n(const Locale('xx'), const {});
      expect(empty.appTitle, 'app_title');
    });
  });
}


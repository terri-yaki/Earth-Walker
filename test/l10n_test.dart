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
  'finding_location': 'Finding your location…',
  'first_run_hint': 'Walk around to discover new places. Visited areas appear as green circles.',
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
  'onboarding_pitch': 'Walk your city. Unlock badges as you explore new neighbourhoods.',
  'onboarding_get_started': 'Get Started',
  'onboarding_loc_off': 'Location services are off. Please turn them on in Settings, then come back.',
  'onboarding_perm_denied': 'Urbix HK needs your location to track where you explore. Please allow it and try again.',
  'onboarding_perm_denied_forever': 'Location permission is permanently denied. Enable it in Settings to use Urbix HK.',
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
};

const Map<String, String> _zhStrings = <String, String>{
  'app_title': 'Urbix 香港',
  'menu_achievements': '成就',
  'menu_medals': '獎牌',
  'menu_districts': '地區',
  'menu_reset': '重設進度',
  'menu_share': '分享進度',
  'reset_dialog_title': '確定要重設進度？',
  'reset_dialog_body': '將會永久清除你所有探索記錄。',
  'reset_dialog_confirm': '重設',
  'reset_dialog_cancel': '取消',
  'reset_dialog_copy': '複製',
  'share_dialog_title': '分享你嘅進度',
  'share_dialog_copy': '複製',
  'share_dialog_copied': '已複製。傳畀朋友啦！',
  'menu_compare': '與朋友比較',
  'compare_dialog_title': '與朋友比較',
  'compare_dialog_paste_hint': '貼上你朋友嘅快照',
  'compare_dialog_compare': '比較',
  'compare_dialog_you': '你',
  'compare_dialog_them': '佢哋',
  'compare_dialog_close': '關閉',
  'compare_dialog_you_win': '你贏咗',
  'compare_dialog_they_win': '佢哋贏咗',
  'compare_dialog_you_tie': '打和',
  'compare_dialog_parse_failed': '睇落唔似 Urbix 香港嘅快照。',
  'compare_dialog_tied': '每項指標都打和！',
  'progress_copied': '已複製進度至剪貼簿。',
  'progress_reset_done': '已重設進度。',
  'finding_location': '正在定位…',
  'first_run_hint': '周圍行吓啦，探索新地方。已到訪嘅範圍會以綠圈顯示。',
  'hud_explored': '已探索',
  'hud_visit': '次到訪',
  'hud_visits': '次到訪',
  'hud_today': '今日',
  'hud_streak': '連續',
  'hud_day_streak': '日',
  'hud_days_streak': '日',
  'hud_next_milestone': '下一個',
  'hud_cells_to_go': '仲差',
  'screen_achievements': '成就',
  'screen_medals': '獎牌',
  'screen_districts': '地區',
  'onboarding_pitch': '行勻全城，探索新地區，賺取勳章。',
  'onboarding_get_started': '開始使用',
  'onboarding_loc_off': '定位服務未開啟。請到「設定」開啟後再試。',
  'onboarding_perm_denied': 'Urbix 香港需要存取你嘅位置先可以記錄到訪過嘅地方。請允許後再試。',
  'onboarding_perm_denied_forever': '定位權限已被永久拒絕。請到「設定」開啟，先可以用 Urbix 香港。',
  'onboarding_loc_error_prefix': '無法取得位置：',
  'badges_header': '勳章',
  'badges_empty': '你仲未拎到任何勳章。继续探索，等你解鎖第一個！',
  'badge_unlocked_at': '解鎖門檻',
  'medals_earned': '已獲得',
  'medals_awarded_at': '頒發門檻',
  'cell_singular': '格',
  'cell_plural': '格',
  'districts_explored': '個地區已探索',
  'badge_unlock_header': '勳章解鎖！',
};

void main() {
  group('resolveLocale', () {
    test('returns exact match when present', () {
      expect(resolveLocale(const Locale('zh', 'HK')),
          const Locale('zh', 'HK'));
      expect(resolveLocale(const Locale('en')), const Locale('en'));
    });

    test('falls back to language-only match', () {
      // zh-TW should resolve to zh-HK since we don't ship zh-TW
      // but the language code matches.
      expect(resolveLocale(const Locale('zh', 'TW')),
          const Locale('zh', 'HK'));
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
      expect(zh.onboardingPermDeniedForever,
          matches(RegExp(r'[\u4E00-\u9FFF]')));
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

    test('missing key falls back to the fallback map, then to the key',
        () {
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

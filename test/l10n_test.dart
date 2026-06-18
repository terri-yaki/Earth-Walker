import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urbix/utils/l10n.dart';

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
      final l = L10n(const Locale('en'));
      expect(l.appTitle, 'Urbix HK');
      expect(l.menuAchievements, 'Achievements');
      expect(l.menuMedals, 'Medals');
      expect(l.menuDistricts, 'Districts');
      expect(l.menuReset, 'Reset Progress');
    });

    test('zh-HK strings are non-empty and contain Chinese characters', () {
      final l = L10n(const Locale('zh', 'HK'));
      // Spot-check: the menu entries should be Chinese, not English.
      expect(l.menuAchievements, isNot('Achievements'));
      expect(l.menuMedals, isNot('Medals'));
      expect(l.menuDistricts, isNot('Districts'));
      expect(l.menuReset, isNot('Reset Progress'));
      // The Chinese strings should contain CJK Unified Ideographs.
      expect(l.menuAchievements, matches(RegExp(r'[\u4E00-\u9FFF]')));
      expect(l.appTitle, matches(RegExp(r'[\u4E00-\u9FFF]')));
    });

    test('missing key falls back to English', () {
      // Construct an empty-locale L10n so the table lookup misses
      // for every key. The fallback to 'en' should kick in.
      final l = L10n(const Locale('xx'));
      expect(l.appTitle, 'Urbix HK');
    });
  });
}

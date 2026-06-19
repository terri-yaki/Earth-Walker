// test/tier_styling_test.dart
//
// Locks the tier -> colour / label mapping so any palette or
// label-key change surfaces here rather than as a silent visual
// regression in the achievement or medal screens.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urbix/providers/achievement_provider.dart'
    show AchievementTier;
import 'package:urbix/utils/l10n.dart';
import 'package:urbix/utils/tier_styling.dart';

import 'helpers/test_l10n.dart';

void main() {
  group('tierColor', () {
    test('gold tier returns the muted gold hex', () {
      expect(tierColor(AchievementTier.gold).value, 0xFFD4A017);
    });

    test('silver tier returns the muted silver hex', () {
      expect(tierColor(AchievementTier.silver).value, 0xFF8E96A1);
    });

    test('bronze tier returns the muted bronze hex', () {
      expect(tierColor(AchievementTier.bronze).value, 0xFFB87333);
    });
  });

  group('tierLabel', () {
    test('returns the localised tier label', () {
      final en = L10n(const Locale('en'), const {
        'tier_gold': 'GOLD',
        'tier_silver': 'SILVER',
        'tier_bronze': 'BRONZE',
      });
      expect(tierLabel(AchievementTier.gold, en), 'GOLD');
      expect(tierLabel(AchievementTier.silver, en), 'SILVER');
      expect(tierLabel(AchievementTier.bronze, en), 'BRONZE');
    });

    test('falls back to the inlined map under the test L10n delegate',
        () async {
      // Real l10n keys are loaded from disk under [TestL10nDelegate].
      // Verify that the delegate maps to the same strings the
      // achievement/medal screens render in production.
      final delegate = TestL10nDelegate();
      final l = await delegate.load(const Locale('en'));
      expect(tierLabel(AchievementTier.gold, l), l.tierGold);
      expect(tierLabel(AchievementTier.silver, l), l.tierSilver);
      expect(tierLabel(AchievementTier.bronze, l), l.tierBronze);
    });
  });
}

// test/helpers/test_l10n.dart
//
// Test-only L10n delegate. The production [L10nDelegate] reads
// from rootBundle, which requires Flutter's asset pipeline and
// doesn't work in plain `flutter test` runs that bypass the
// asset bundling step. This delegate reads the JSON files from
// the assets/l10n/ directory on disk via dart:io instead, so
// widget tests can drive `L10n.of(context)` and exercise the
// real copy without needing a manual stub for every key.
//
// ponytail: we deliberately don't add a rootBundle-backed fallback
// in production code just to support tests. One file in the test
// tree is cheaper than coupling the production L10n to dart:io.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';

import 'package:urbix/utils/l10n.dart';

class TestL10nDelegate extends LocalizationsDelegate<L10n> {
  const TestL10nDelegate();

  @override
  bool isSupported(Locale locale) =>
      kSupportedLocales.any((l) => l.languageCode == locale.languageCode);

  @override
  Future<L10n> load(Locale locale) async {
    final resolved = resolveLocale(locale);
    final tag = resolved.toLanguageTag(); // 'en' or 'zh-HK'
    final strings = _loadTagSync(tag);
    final fallback = _loadTagSync('en');
    return L10n(resolved, strings, fallback);
  }

  @override
  bool shouldReload(TestL10nDelegate old) => false;

  /// Public re-export of [_loadTagSync] so test/l10n_test.dart
  /// can drift-check the on-disk JSON against the inlined maps
  /// without re-implementing the file-lookup logic.
  Map<String, String> loadTagSyncForTests(String tag) => _loadTagSync(tag);

  /// Read assets/l10n/<tag>.json from disk and return the parsed
  /// string map. Returns an empty map if the file is missing or
  /// malformed so a stray missing-file doesn't crash the whole
  /// test suite —it just renders raw keys.
  Map<String, String> _loadTagSync(String tag) {
    // Walk up from the test working directory until we find the
    // assets folder. `flutter test` sets the cwd to the project
    // root, so a single `assets/...` lookup usually works; the
    // `../...` fallback handles unusual layouts where the runner
    // sets cwd to a subdirectory.
    final candidates = <File>[
      File('assets/l10n/$tag.json'),
      File('../assets/l10n/$tag.json'),
    ];
    for (final f in candidates) {
      if (f.existsSync()) {
        try {
          final raw = f.readAsStringSync();
          final decoded = json.decode(raw) as Map<String, dynamic>;
          // ignore: avoid_print
          print(
              'TestL10n: loaded $tag from ${f.path} (${decoded.length} keys)');
          return decoded.map((k, v) => MapEntry(k, v.toString()));
        } catch (e) {
          // ignore: avoid_print
          print('TestL10n: failed to load $tag from ${f.path}: $e');
          return const <String, String>{};
        }
      }
    }
    // ignore: avoid_print
    print('TestL10n: no file found for $tag, tried ${candidates.length} paths');
    return const <String, String>{};
  }
}

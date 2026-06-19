// test/source_utf8_test.dart
//
// Regression guard for the UTF-8 byte corruption bug. Earlier
// edits to lib/screens/map_screen.dart and lib/utils/share_text.dart
// wrote the middle-dot character (·, U+00B7) through a terminal
// pipeline that mangled the bytes into 0xe8 0x9d 0x9c —the UTF-8
// encoding of U+E85C (a Private Use Area code point that has no
// glyph in the system font). The user then saw a stray "蝜?" or
// garbled glyph in the HUD instead of the intended middle-dot
// separator.
//
// Lock that down: every .dart file under lib/ must not contain
// the corruption bytes 0xe8 0x9d 0x9c. If a future edit lands
// them again, this test fails at CI before the buggy build ships.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lib/**/*.dart contains no corrupted middle-dot bytes (0xe8 0x9d 0x9c)',
      () {
    final root = Directory('lib');
    expect(root.existsSync(), isTrue,
        reason: 'lib/ should exist relative to the test cwd');
    final offenders = <String>[];
    void walk(FileSystemEntity e) {
      if (e is Directory) {
        for (final child in e.listSync()) {
          walk(child);
        }
      } else if (e is File && e.path.endsWith('.dart')) {
        final bytes = e.readAsBytesSync();
        if (bytes.contains(0xe8) && bytes.contains(0x9d)) {
          // Cheap scan: any file that contains both 0xe8 and
          // 0x9d needs a closer look (most files won't have
          // either byte). Count the specific 3-byte sequence
          // and collect offenders.
          var i = 0;
          var hits = 0;
          while (i < bytes.length - 2) {
            if (bytes[i] == 0xe8 &&
                bytes[i + 1] == 0x9d &&
                bytes[i + 2] == 0x9c) {
              hits++;
            }
            i++;
          }
          if (hits > 0) {
            offenders.add('${e.path}: $hits occurrence(s)');
          }
        }
      }
    }

    walk(root);
    expect(offenders, isEmpty,
        reason: 'lib/**/*.dart must not contain the corrupted middle-dot '
            'bytes 0xe8 0x9d 0x9c (UTF-8 of U+E85C). Offending files: '
            '$offenders. Fix by replacing with proper UTF-8 of the '
            'middle-dot U+00B7 (0xc2 0xb7) via Python or a UTF-8-aware '
            'editor.');
  });
}

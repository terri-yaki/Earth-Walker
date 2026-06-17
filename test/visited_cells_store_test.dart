import 'package:flutter_test/flutter_test.dart';
import 'package:urbix/utils/visited_cells_store.dart';

void main() {
  group('cellsToJson', () {
    test('null and empty both serialize to "[]"', () {
      expect(cellsToJson(null), '[]');
      expect(cellsToJson(<String>{}), '[]');
    });

    test('serializes a populated set to a JSON array', () {
      expect(cellsToJson({'wecss', 'wecsr'}), '["wecss","wecsr"]');
    });
  });

  group('cellsFromJson', () {
    test('null and empty both decode to an empty set', () {
      expect(cellsFromJson(null), isEmpty);
      expect(cellsFromJson(''), isEmpty);
    });

    test('round-trips through toJson/fromJson', () {
      final original = {'wecss', 'wecsr', 'wecz1'};
      expect(cellsFromJson(cellsToJson(original)), original);
    });

    test('returns empty set on malformed input (does not throw)', () {
      expect(cellsFromJson('not json'), isEmpty);
      expect(cellsFromJson('{"unexpected": "object"}'), isEmpty);
      expect(cellsFromJson('123'), isEmpty);
    });

    test('filters out non-string entries', () {
      // A list of mixed types should drop non-strings rather than crash.
      final decoded = cellsFromJson('["a", 1, null, "b"]');
      expect(decoded, equals(<String>{'a', 'b'}));
    });
  });
}

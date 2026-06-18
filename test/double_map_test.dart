import 'package:flutter_test/flutter_test.dart';
import 'package:urbix/utils/double_map.dart';

void main() {
  group('doubleMapToJson', () {
    test('null and empty both serialize to "{}"', () {
      expect(doubleMapToJson(null), '{}');
      expect(doubleMapToJson(<String, double>{}), '{}');
    });

    test('serializes a populated map to a JSON object', () {
      expect(
        doubleMapToJson({'2026-06-17': 1234.5, '2026-06-16': 678.9}),
        '{"2026-06-17":1234.5,"2026-06-16":678.9}',
      );
    });
  });

  group('doubleMapFromJson', () {
    test('null and empty both decode to an empty map', () {
      expect(doubleMapFromJson(null), isEmpty);
      expect(doubleMapFromJson(''), isEmpty);
    });

    test('round-trips through toJson/fromJson', () {
      final original = <String, double>{
        '2026-06-17': 1234.5,
        '2026-06-16': 678.9,
      };
      expect(doubleMapFromJson(doubleMapToJson(original)), original);
    });

    test('returns empty map on malformed input (does not throw)', () {
      expect(doubleMapFromJson('not json'), isEmpty);
      expect(doubleMapFromJson('[]'), isEmpty);
      expect(doubleMapFromJson('"a string"'), isEmpty);
    });

    test('coerces numeric values (int or double) to double', () {
      // jsonDecode returns ints for whole numbers; both should round-
      // trip to doubles.
      final decoded = doubleMapFromJson('{"a":3,"b":5.0}');
      expect(decoded, equals(<String, double>{'a': 3.0, 'b': 5.0}));
    });
  });
}

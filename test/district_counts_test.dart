import 'package:flutter_test/flutter_test.dart';
import 'package:urbix/utils/district_counts.dart';

void main() {
  group('districtCountMapToJson', () {
    test('null and empty both serialize to "{}"', () {
      expect(districtCountMapToJson(null), '{}');
      expect(districtCountMapToJson(<String, int>{}), '{}');
    });

    test('serializes a populated map to a JSON object', () {
      expect(
        districtCountMapToJson({'Central and Western': 4, 'Wan Chai': 1}),
        '{"Central and Western":4,"Wan Chai":1}',
      );
    });
  });

  group('districtCountMapFromJson', () {
    test('null and empty both decode to an empty map', () {
      expect(districtCountMapFromJson(null), isEmpty);
      expect(districtCountMapFromJson(''), isEmpty);
    });

    test('round-trips through toJson/fromJson', () {
      final original = <String, int>{
        'Central and Western': 4,
        'Wan Chai': 1,
        'Yau Tsim Mong': 12,
      };
      expect(
          districtCountMapFromJson(districtCountMapToJson(original)), original);
    });

    test('returns empty map on malformed input (does not throw)', () {
      expect(districtCountMapFromJson('not json'), isEmpty);
      expect(districtCountMapFromJson('[]'), isEmpty);
      expect(districtCountMapFromJson('"a string"'), isEmpty);
    });

    test('coerces numeric values (int or double) to int', () {
      // jsonDecode returns doubles for numbers without explicit int.
      final decoded = districtCountMapFromJson('{"a":3,"b":5.0}');
      expect(decoded, equals(<String, int>{'a': 3, 'b': 5}));
    });

    test(
        'a single non-numeric value does not discard the rest '
        '(regression for the "one bad value nukes every district" bug)',
        () {
      // The previous implementation had
      // `(v as num).toInt()` inside a try/catch around the
      // whole map, so a single string value threw and silently
      // dropped every other district's count.
      final decoded = districtCountMapFromJson(
          '{"Central and Western":4,"Yau Tsim Mong":"12","Wan Chai":1}');
      expect(
          decoded,
          equals(<String, int>{
            'Central and Western': 4,
            'Wan Chai': 1,
            // 'Yau Tsim Mong' skipped because "12" is a string.
          }));
    });
  });
}

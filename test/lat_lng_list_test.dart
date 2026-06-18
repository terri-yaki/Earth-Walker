import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:urbix/utils/lat_lng_list.dart';

void main() {
  group('latLngListToJson', () {
    test('null and empty both serialize to "[]"', () {
      expect(latLngListToJson(null), '[]');
      expect(latLngListToJson(<LatLng>[]), '[]');
    });

    test('serializes a populated list to a JSON array of [lat, lng] pairs',
        () {
      expect(
        latLngListToJson(const [
          LatLng(22.298, 114.170),
          LatLng(22.330, 114.180),
        ]),
        '[[22.298,114.17],[22.33,114.18]]',
      );
    });
  });

  group('latLngListFromJson', () {
    test('null and empty both decode to an empty list', () {
      expect(latLngListFromJson(null), isEmpty);
      expect(latLngListFromJson(''), isEmpty);
    });

    test('round-trips through toJson/fromJson', () {
      final original = <LatLng>[
        const LatLng(22.298, 114.170),
        const LatLng(22.330, 114.180),
        const LatLng(22.500, 114.000),
      ];
      expect(latLngListFromJson(latLngListToJson(original)), original);
    });

    test('returns empty list on malformed input (does not throw)', () {
      expect(latLngListFromJson('not json'), isEmpty);
      expect(latLngListFromJson('"a string"'), isEmpty);
      expect(latLngListFromJson('{}'), isEmpty);
    });

    test('skips entries that are not [lat, lng] pairs', () {
      // Mixed valid + invalid entries; only the valid ones should
      // come back.
      final decoded = latLngListFromJson(
          '[[22.1, 114.1], "bad", [22.2], [22.3, 114.3]]');
      expect(decoded, equals(<LatLng>[
        const LatLng(22.1, 114.1),
        const LatLng(22.3, 114.3),
      ]));
    });
  });
}

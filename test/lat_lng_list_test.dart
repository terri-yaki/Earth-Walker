import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:urbix/utils/lat_lng_list.dart';

void main() {
  group('latLngListToJson', () {
    test('null and empty both serialize to "[]"', () {
      expect(latLngListToJson(null), '[]');
      expect(latLngListToJson(<LatLng>[]), '[]');
    });

    test('serializes a populated list to a JSON array of [lat, lng] pairs', () {
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
      final decoded =
          latLngListFromJson('[[22.1, 114.1], "bad", [22.2], [22.3, 114.3]]');
      expect(
          decoded,
          equals(<LatLng>[
            const LatLng(22.1, 114.1),
            const LatLng(22.3, 114.3),
          ]));
    });

    test(
        'a single bad entry does not discard the rest (regression for the '
        '"one TypeError nukes the whole list" bug)', () {
      // The previous implementation had `try { ... return out; }
      // catch (_) { return []; }` around the whole loop. Any
      // per-entry TypeError (e.g. a string coerced via
      // `entry[0] as num`) would short-circuit the entire
      // decoder and return [], silently dropping every earlier
      // valid point.
      //
      // After the fix: each entry is decoded independently.
      // The string-lng entry is skipped, and the trailing valid
      // entry survives.
      final decoded = latLngListFromJson(
          '[[22.1, 114.1], [22.2, "114.2"], [22.3, 114.3]]');
      expect(
          decoded,
          equals(<LatLng>[
            const LatLng(22.1, 114.1),
            const LatLng(22.3, 114.3),
          ]));
    });

    test('rejects out-of-range lat/lng (corrupted prefs safety)', () {
      // A corrupted prefs file with [[999, 999]] would
      // previously produce a LatLng(999, 999) that the map
      // renderer would happily try to plot at (999°N, 999°E)
      // —a coordinate that doesn't exist on Earth. Range-check
      // both fields.
      expect(latLngListFromJson('[[999, 999]]'), isEmpty);
      expect(latLngListFromJson('[[22.5, 999]]'), isEmpty);
      expect(latLngListFromJson('[[999, 114.1]]'), isEmpty);
      // Boundary values are still valid.
      expect(latLngListFromJson('[[90, 180], [-90, -180]]'),
          equals(<LatLng>[const LatLng(90, 180), const LatLng(-90, -180)]));
    });
  });
}

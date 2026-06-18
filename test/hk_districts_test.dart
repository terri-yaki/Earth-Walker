import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:urbix/utils/hk_districts.dart';

void main() {
  group('districtFor', () {
    test('resolves known landmarks to their district', () {
      // Central Government Offices, Tamar.
      expect(districtFor(const LatLng(22.281, 114.158))?.name,
          'Central and Western');
      // Tsim Sha Tsui Clock Tower.
      expect(districtFor(const LatLng(22.298, 114.170))?.name, 'Yau Tsim Mong');
      // Sha Tin Town Hall.
      expect(districtFor(const LatLng(22.381, 114.187))?.name, 'Sha Tin');
      // Hong Kong International Airport (on Lantau).
      expect(districtFor(const LatLng(22.308, 113.918))?.name, 'Islands');
    });

    test('returns null for a point well outside HK', () {
      // Sydney.
      expect(districtFor(const LatLng(-33.87, 151.21)), isNull);
    });

    test('contains() respects the closed interval on all four sides', () {
      const d = HkDistrict(
          name: 'Test',
          minLat: 22.0,
          maxLat: 23.0,
          minLng: 114.0,
          maxLng: 115.0);
      expect(d.contains(const LatLng(22.0, 114.0)), isTrue);
      expect(d.contains(const LatLng(23.0, 115.0)), isTrue);
      expect(d.contains(const LatLng(21.999, 114.0)), isFalse);
      expect(d.contains(const LatLng(22.0, 115.001)), isFalse);
    });
  });
}


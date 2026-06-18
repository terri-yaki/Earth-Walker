// lib/screens/districts_screen.dart
//
// Per-district breakdown of visited-cell counts. All 18 HK
// districts, sorted by visit count (descending). Districts with
// zero visits show a muted "—" rather than a misleading 0, and
// sit at the bottom of the list.
//
// ponytail: deliberately no "X% explored" per district — we don't
// have an honest denominator (different districts have different
// total cell counts at geohash-5), so a percentage would be a
// lie. Absolute counts are honest.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/userlocation_provider.dart';
import '../utils/hk_districts.dart';
import '../utils/l10n.dart';

class DistrictsScreen extends StatelessWidget {
  const DistrictsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final visits = context.watch<UserLocationProvider>().visitsByDistrict;
    final names = allDistrictNames;
    final explored = names.where((n) => (visits[n] ?? 0) > 0).length;

    // Sort: visited districts first (by count desc), then unvisited
    // (alphabetical, so the list is still predictable).
    final sorted = [...names]..sort((a, b) {
        final ca = visits[a] ?? 0;
        final cb = visits[b] ?? 0;
        if (ca == 0 && cb == 0) return a.compareTo(b);
        if (ca == 0) return 1;
        if (cb == 0) return -1;
        return cb.compareTo(ca);
      });

    return Scaffold(
      appBar: AppBar(
        title: Text(l.screenDistricts),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            '$explored of ${names.length} ${l.districtsExplored}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...sorted.map((name) => _buildRow(name, visits[name] ?? 0)),
        ],
      ),
    );
  }

  Widget _buildRow(String name, int count) {
    final l = L10n.of(context);
    final visited = count > 0;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        visited ? Icons.location_city : Icons.location_off_outlined,
        color: visited ? Colors.green : Colors.grey,
      ),
      title: Text(
        name,
        style: TextStyle(
          fontWeight: visited ? FontWeight.bold : FontWeight.normal,
          color: visited ? Colors.black : Colors.grey.shade600,
        ),
      ),
      trailing: Text(
        visited
            ? '$count ${count == 1 ? l.cellSingular : l.cellPlural}'
            : '—',
        style: TextStyle(
          color: visited ? Colors.black : Colors.grey,
          fontWeight: visited ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}

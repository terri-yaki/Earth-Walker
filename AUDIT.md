# Urbix HK — audit findings

## Open

### A1. `UserLocationProvider` has no direct unit tests

- All other providers (`AchievementProvider`, `MedalProvider`) have tests.
- All pure helpers (`geohash`, `exploration_days`, `format_distance`,
  `progress_summary`, `visited_cells_store`, `district_counts`,
  `hk_districts`) have tests.
- `UserLocationProvider` is the largest provider in the app — owns the
  visited-cell set, cumulative distance, days-explored, per-district
  counts, and all the persistence plumbing — and has no test coverage
  for any of it. The behaviour has only ever been exercised by
  `flutter run` on a real device.
- Difficulty: medium. Most of its methods are pure or take constructor
  arguments; the only real blocker is `updateUserLocation()` which
  calls `Geolocator.getCurrentPosition()` and would need a mock or a
  refactor to inject a position source.
- **Fix in this commit series**: add `userlocation_provider_test.dart`
  covering everything except `updateUserLocation()` (geohash precision
  constant, `currentDistrictName`, `cellsInCurrentDistrict`,
  `setRecentered`, `updateZoom`, `resetExploration` clearing every
  counter, and the `visitsByDistrict` getter). Leave
  `updateUserLocation()` for a follow-up that injects a position
  source.

## Closed by this audit

- No leftover `print()` calls — all uses were replaced with
  `debugPrint` in earlier cleanup.
- No leftover `TODO` / `FIXME` / `XXX` / `HACK` comments.
- All `catch (_)` blocks are intentional defensive fallbacks in
  pure JSON parsers and a tear-down listener removal.
- 9 `notifyListeners()` call sites across the three providers; the
  single notify per `updateUserLocation` cycle is correct (both
  private helpers `_accumulateDistance` and `_updateExploration`
  update state but defer to the caller's notify — contained because
  they are private).

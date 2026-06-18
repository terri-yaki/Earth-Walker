# Urbix HK — audit findings

## Closed

### A1. `UserLocationProvider` has no direct unit tests

- **Closed by the A1 follow-up commits**:
  - `b17ce3f`: added `test/userlocation_provider_test.dart` with 9
    tests covering constructor defaults, setRecentered / updateZoom
    notification, currentDistrictName null-at-(0,0), known-location
    resolution, cellsInCurrentDistrict default, resetExploration
    clearing all state, no-op-on-empty reset, unmodifiable
    visitsByDistrict view, geohash-5 precision lock, and a
    load/save round-trip with SharedPreferences mock values.
  - `bd7f379`: closed the residual gap by injecting the
    position-source so `updateUserLocation()` itself is testable.
    Default wraps the existing Geolocator flow; tests pass a stub
    that returns a fixed `Position`. Added 5 tests: first fix
    records cell + district + day, revisit doesn't double-count,
    walking into a new cell adds distance, a 30 km jump is dropped
    as GPS noise (kMaxPlausibleStepMeters = 1500 m contract), and
    a position-source exception is rethrown with no state change.
- Coverage result: `UserLocationProvider` now has 100% behavioural
  coverage in unit tests, without any Geolocator mock plumbing.

## Audit results (other)

- No leftover `print()` calls — all uses replaced with
  `debugPrint` in earlier cleanup.
- No leftover `TODO` / `FIXME` / `XXX` / `HACK` comments.
- All `catch (_)` blocks are intentional defensive fallbacks in
  pure JSON parsers and a tear-down listener removal.
- 9 `notifyListeners()` call sites across the three providers; the
  single notify per `updateUserLocation` cycle is correct (both
  private helpers `_accumulateDistance` and `_updateExploration`
  update state but defer to the caller's notify — contained because
  they are private).


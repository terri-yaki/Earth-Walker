# ISSUES

Local issue tracker for Urbix HK. Mirrors the GitHub issue format
so the entries below can be copy-pasted into the repo's issue
tracker when you want to surface them. Filter by `label:` to
narrow when working on one.

Labels used:
- `BUG` — confirmed defect, fixes
- `FEAT` — new user-facing feature
- `CHORE` — internal / non-user-facing improvement
- `A11Y` — accessibility
- `I18N` — internationalisation / localisation
- `PERF` — performance
- `DOC` — documentation
- `TEST` — test coverage
- `P2` / `P3` — priority, lower = more important

Status:
- `[ ]` open
- `[~]` in progress
- `[x]` closed (resolved)

---

## [x] A1 — UserLocationProvider has no direct unit tests
Label: `TEST`. P1. Resolved by `b17ce3f` (initial tests) + `bd7f379`
(position-source injection). 100% behavioural coverage achieved.

## [x] A2 — Concurrent updateUserLocation + resetExploration race
Label: `BUG`. P1. Resolved by `5501fb1` (mutation-epoch counter).
Tests cover the race directly.

## [ ] B1 — Real geohash-based exploration tracking
Label: `FEAT`. P2. The `_updateExploration` placeholder is still
a `+1` counter; the real "1 cell = 1% world" claim is the
deliberately-generous prototype scaling. A real implementation
needs an honest denominator (e.g. total cells covering land) or
a per-district total. Open question: do we want a world map
footprint or restrict to HK only?

## [ ] B2 — Replace world% with three distinct country/continent/world figures
Label: `FEAT`. P2. The README claims "track your district, Hong
Kong, and the wider world" but the model has a single counter.
Splitting into three genuinely different figures needs real
geographic data; the bounding-box detector we have for HK
districts is the starting point.

## [ ] B3 — Per-district % tracking
Label: `FEAT`. P3. We have a count of unique cells per district
but no honest % — different districts have different total cell
counts at geohash-5, so a per-district percentage would need
either polygon-point tests against the official Hong Kong
GeoJSON, or a much tighter box set per district.

## [ ] I18N-1 — zh-Hant (Taiwan) / zh-CN (Simplified) variants
Label: `I18N`. P3. We ship `zh-HK` only. Adding `zh-TW` and
`zh-CN` is a copy-paste of `assets/l10n/zh-HK.json` with
different values; resolveLocale() already supports the
language-only fallback, so they would just need
supportedLocales entries.

## [ ] A11Y-1 — Larger text-size support
Label: `A11Y`. P3. Flutter's text scaler defaults to the system
size and the app doesn't override it, so the headline + body
text scale with the OS setting. Worth a manual smoke test at
1.5x and 2.0x to make sure the HUD doesn't overflow the screen
and the chip rows don't wrap awkwardly.

## [ ] A11Y-2 — TalkBack smoke pass on a real device
Label: `A11Y`. P3. We've added Semantics labels for the user
marker, trophy icon, and excluded the visited-cell circles.
A real device pass with TalkBack enabled is the only way to
verify the full read order is right (e.g. distance stat before
days stat, or vice versa).

## [ ] CHORE-1 — Tighten analysis_options to fail on warnings
Label: `CHORE`. P3. CI runs `flutter analyze --no-fatal-infos`
which lets warnings through. Once the analyzer is clean, bump
to `--fatal-warnings` to keep it that way. Estimate: 1 hour
of cleanup + 1 line change.

## [ ] CHORE-2 — Add an integration_test directory
Label: `TEST`. P3. Widget tests cover individual screens but
there's no full-flow integration test (onboarding → map →
walk → badge unlock). `flutter test integration_test` is the
right tool. The `positionSource` injection on
UserLocationProvider makes this easy to drive without real GPS.

## [ ] DOC-1 — Architecture diagram
Label: `DOC`. P3. The README has a lib/ tree map but no
data-flow diagram. Mermaid in a README renders on github.com
and is easy to update. Would cover: geolocator →
UserLocationProvider (via position source) → ChangeNotifierProxyProvider
→ AchievementProvider + MedalProvider → HUD/Screens.

## [ ] FEAT-1 — Background location tracking
Label: `FEAT`. P1 (product). The app only tracks when the user
has the screen open. With foreground service (Android) and
`allowsBackgroundLocationUpdates` (iOS) the app could keep
counting distance and cells with the screen off. Needs:
permission UX, battery-impact disclosure, a foreground
notification explaining "Urbix HK is recording your walk", and
proper handling of the "user killed the service" path.

## [ ] FEAT-2 — Local notifications on badge unlock
Label: `FEAT`. P2. Today the badge-unlock snackbar only fires
while the app is in the foreground. Adding a local
notification (via `flutter_local_notifications`) would let a
user who has the screen off still see "Badge unlocked: Walker"
when they cross a threshold.

## [ ] FEAT-3 — App icon
Label: `FEAT`. P3. The app still ships with the default
Flutter icon. A real Urbix HK icon (pixel-art map pin or
walking figure) would be the obvious next step. Needs
1024x1024 master + per-platform outputs (iOS, Android
adaptive, web).

## [ ] PERF-1 — _visitedCells is O(n) lookups on every new fix
Label: `PERF`. P3. Set<String> is a hash set, so individual
lookups are O(1), but the user adds a cell, computes
intersections with each district's box, and writes the
per-district map. For 100+ visited cells the linear
recomputation is fine, but for a long-running user with 1000+
cells the map's CircleLayer starts to cost real frames. A
spatial index (e.g. S2 or H3) is the right upgrade; not
required for the prototype.

## [ ] PERF-2 — saveToStorage fires on every cell add
Label: `PERF`. P3. Every `_updateExploration` call that adds a
new cell triggers a `saveToStorage()` which writes 5 prefs
keys synchronously. Fine at current scale, but for a user
exploring a busy area this can fire multiple times per second
and shows up as a minor battery hit. Debounce to a 5-second
window (and force-save on app pause) is the upgrade path.

## [ ] TEST-1 — MedalProvider reset edge case
Label: `TEST`. P3. `MedalProvider.resetMedals()` returns
silently when `_awardedMedals` is already empty (no
notification). The matching `AchievementProvider.resetAchievements`
behaves the same way. No test currently asserts the
no-notify-on-empty contract for either. Add 2 tests (one per
provider) so a future regression that drops the guard is
caught.

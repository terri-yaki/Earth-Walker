# Urbix HK

**Urbix HK** is a Flutter application that turns Hong Kong into your playground. Whether you're weaving through Mong Kok, hiking the Dragon's Back, or just stepping out for milk tea, Urbix HK tracks where you've been and rewards you for getting out the door. Explore districts, earn medals, and watch your map of the city fill in.

---

## 🌟 Features

- **Real-time location tracking on OpenStreetMap**  
  Your current location is shown on an interactive map. The recenter FAB snaps the view back to you if you pan away. Screen-reader users hear "You are here" at the marker.

- **Geohash-based visited-cell tracking**  
  Each new geohash-5 cell (~2.4 km squares) you enter is recorded once. Revisiting the same cell is a no-op. Visited cells render as translucent green circles on the map; the count, total distance, and days-explored appear in the HUD.

- **Per-district breakdown**  
  All 18 Hong Kong districts are recognised via bounding-box detection. The HUD shows your current district, and the Districts screen lists every district with the number of cells you've recorded there, sorted by visit count.

- **7-step achievement ladder**  
  Walker (10%) → Pioneer → Traveller → Explorer → Coloniser → Dominator → "Are you sure you're not cheating?" (99%). Each tier is styled in muted bronze / silver / gold. Crossing a threshold fires a haptic, a green celebration snackbar, and unlocks the next badge in the Achievements screen.

- **Medal system**  
  A parallel 7-medal set, awarded on the same world-% thresholds, with the same tier styling.

- **Progress toward the next milestone**  
  The HUD shows a tier-coloured progress bar anchored at your last unlocked threshold, so the bar always reads as the right shape — empty for a fresh user, half-full mid-tier, full at the next threshold.

- **Reset progress**  
  The drawer's Reset Progress action wipes visited cells, unlocked badges, and awarded medals after a confirmation dialog. The dialog includes a Copy button so you can save a text summary of your stats before wiping.

- **First-run onboarding**  
  First launch runs through the Geolocator permission flow with distinct messaging for each denial outcome (denied / denied-forever / service off). On subsequent launches, the flag short-circuits straight to the map.

- **Persistence**  
  All progress (visited cells, walking distance, days explored, per-district counts, unlocked badges, awarded medals, onboarding flag) is written to SharedPreferences and restored on app start.

- **Bilingual UI (English / 繁體中文)**  
  Every user-facing string is routed through a hand-rolled `L10n` class with both `en` and `zh-HK` translations. A user with a Hong Kong device locale sees the app in Traditional Chinese.

- **Accessibility**  
  Semantics labels on the user marker and badge icon; visited-cell circles excluded from the semantics tree; the Recenter FAB has a tooltip; the next-milestone chip reads "Next: X at Y% · Z to go".

---

## 🛠 Architecture (short tour)

```
lib/
  main.dart                    # MultiProvider + MaterialApp with L10nDelegate
  models/                      # Plain Dart value objects (UserLocation)
  providers/                   # ChangeNotifier state (userlocation / achievement / medal)
  screens/                     # Onboarding, Map, Achievements, Medals, Districts
  widgets/                     # HamburgerMenu, RecentrButton, CustomText
  utils/                       # Pure helpers: geohash, l10n, hk_districts, district_counts,
                              #   explored_days, format_distance, progress_summary,
                              #   visited_cells_store
test/                          # 12 test files, ~70 unit + widget tests
AUDIT.md                       # Open / closed audit findings (currently: nothing open)
.github/workflows/flutter-ci.yml   # flutter analyze + flutter test on every push
```

### Design choices worth knowing

- **Geohash-5 cells** as the unit of "place visited" — small enough that walking a few hundred metres registers a new cell, large enough that GPS jitter doesn't double-count.
- **No real "X% explored" per district** — different HK districts have wildly different total cell counts, and a per-district percentage would be a lie. The screen shows absolute counts.
- **The Reset Progress dialog is the only screen that builds its own content** with hard-coded English copy. Intentional — it's pure data, not UI copy, and the user copies it out so language doesn't matter.
- **Hand-rolled L10n, no `flutter gen-l10n`** — keeps the project free of generated files and an extra build step. Add a key, write a translation, done.

---

## 🛡 License

Distributed under the CC BY-NC 4.0 License. See `LICENSE` for more information.

---

## # Acknowledgements

- [OpenStreetMap](https://www.openstreetmap.org/) for providing free map data.
- [Flutter Community](https://flutter.dev/community) for amazing resources and support.
- The 18-district bounding boxes are approximations; real boundaries would need polygon-point tests against the official Hong Kong GeoJSON.

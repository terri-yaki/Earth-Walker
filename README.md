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

- **Share + Compare with friends**  
  The drawer's Share Progress action copies a one-line summary of your stats (cells, badges, medals, km, days, streak) plus a parseable snapshot string (`URBIX:SNAP:1:cells=…,badges=…`). A friend can paste the snapshot into Compare with friend and the app shows a per-field delta: "you win on X", "they win on Y", or "tied on everything".

- **System share sheet (real social media)**  
  The Share dialog hands the brag post to the OS share sheet (iOS `UIActivityViewController` / Android `Intent.ACTION_SEND`) so the user can post to Instagram, WhatsApp, X, Threads, Telegram etc. in one tap. The post auto-includes a `#UrbixHK` hashtag and the snapshot string at the bottom for Compare.

- **Streak-milestone auto-prompt**  
  When the user crosses 3, 7, 14, or 30 consecutive exploration days, a one-shot orange "Share your streak?" snackbar pops with an action that opens the share dialog pre-loaded with the streak brag. A small share icon also appears next to the streak chip once it's brag-worthy (≥ 3 days).

- **Exploration-suggestion engine**  
  The HUD's "Next: <district> · <distance>" chip points at the top-ranked unexplored geohash-5 cell. Pure ranking engine: proximity dominates, with a +20% bonus for cells in a district the user hasn't visited yet. Tapping the chip recenters the map on the target and disables auto-recenter so the user can study the destination.

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
  widgets/                     # HamburgerMenu, RecenterButton, CustomText
  utils/                       # Pure helpers: geohash, l10n, hk_districts, district_counts,
                              #   exploration_days, format_distance, progress_summary,
                              #   visited_cells_store, share_text, streak_milestones,
                              #   exploration_suggestion
test/                          # 20 test files, ~85 unit + widget tests
AUDIT.md                       # Open / closed audit findings (currently: nothing open)
ISSUES.md                      # Local issue tracker (FEAT-* / BUG / A11Y / I18N / PERF)
.github/workflows/flutter-ci.yml   # format, analyze, test+coverage (60% floor), build APK
```

### Design choices worth knowing

- **Geohash-5 cells** as the unit of "place visited" — small enough that walking a few hundred metres registers a new cell, large enough that GPS jitter doesn't double-count.
- **No real "X% explored" per district** — different HK districts have wildly different total cell counts, and a per-district percentage would be a lie. The screen shows absolute counts.
- **The share-snapshot format (`URBIX:SNAP:1:key=value,…`)** is intentionally not JSON — JSON inside a share-sheet text gets quote-escaped in some chat apps, and the comma-separated `k=v` form is human-readable enough that a curious recipient can decode it by eye. The version byte (`1:`) lets us evolve the format later without breaking old snapshots.
- **The exploration-suggestion engine returns the top candidate, not a list** — matches the "only pick one for them" UX ask. The full ranking is internal; tests exercise it indirectly by checking the picked winner in two-cell scenarios.
- **`share_plus` for the OS share sheet, not per-platform SDKs** — Instagram / X / Threads / Telegram all have developer-unfriendly terms around automated posting. The share-sheet approach is TOS-compliant for every major social app, with no API keys, no OAuth, no per-platform plugin.
- **The Reset Progress dialog is the only screen that builds its own content** with hard-coded English copy. Intentional — it's pure data, not UI copy, and the user copies it out so language doesn't matter.
- **Hand-rolled L10n, no `flutter gen-l10n`** — keeps the project free of generated files and an extra build step. Add a key, write a translation, done. Translations live in `assets/l10n/{en,zh-HK}.json`; the `L10n` class loads them via `rootBundle`.

---

## 🛡 License

Distributed under the CC BY-NC 4.0 License. See `LICENSE` for more information.

---

## # Acknowledgements

- [OpenStreetMap](https://www.openstreetmap.org/) for providing free map data.
- [Flutter Community](https://flutter.dev/community) for amazing resources and support.
- The 18-district bounding boxes are approximations; real boundaries would need polygon-point tests against the official Hong Kong GeoJSON.

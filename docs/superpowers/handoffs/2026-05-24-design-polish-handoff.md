# Design Polish Pass — Handoff (Phase 2 mid-progress)

> A fresh Claude Code session should be able to continue cleanly from this doc.
> Working dir: `C:\Users\user\Desktop\np` (repo root). Flutter app: `pokerspot/`.
> Branch: `master`. Platform: Windows / PowerShell. Flutter 3.44, Dart 3.12.

## What this work is
Bring the Flutter app to **100% visual parity** with the "Liquid Sport" mockups in
`docs/superpowers/mockups/v3-design-system/` (`tokens.css` = source of truth,
`components.css` = component recipes). Full design-system spec + widget-library
proposal: **`docs/design-system/liquid-sport.md`** (read this first — it has every
color/type/spacing/shadow/gradient/glass/motion token + per-widget mapping + gaps).

Skills to (re)invoke: `apple-hig-designer`, `liquid-glass`, `superpowers:writing-plans`.
(`flutter-all` / `flutter-im5tu` / `flutter-security` were NOT installed — skip.)

## 1. Phase 2 progress (committed)
| Commit | What |
|---|---|
| `9dde90c` | **Token extension** in `lib/core/theme/tokens.dart`: `PsColors` (statusFull, bgBloomA/B, glassThick, glassHighlight); new `PsGlass` (blurThin/Regular/Thick 16/22/30, saturate 1.70, **`saturationMatrix`**, **`backdrop(blur)`**); `PsType` weights (regular/medium/bold/black) + tracking (tight/snug/normal/wide/overline); new `PsElevation` e1–e5; new `PsGradients` (backgroundBase, avatar, glassHighlightLine); `PsMotion` easeDecelerate/easeAccelerate; new `PsLayout.screenPad`. `tokens.dart` imports `dart:ui show ImageFilter`. |
| `17f6d0d` | **PsOverline** + **golden infra** (`test/flutter_test_config.dart` disables GoogleFonts network fetching for deterministic tests/goldens). |
| `08f38b7` | **PsBrand** (italic black wordmark; optional `accent` substring → accent-primary). |
| `5290f5e` | **PsScaffold** (gradient bg: linear base + 2 radial blooms; `RepaintBoundary`). |

**Gate is green:** `flutter analyze` → No issues found! · `flutter test` → **109 passing + 3 skipped**.
(The 3 skips are pre-existing live-Riverpod-stream widget tests — see the
`skip-flaky-riverpod-stream-widget-tests` memory; do not unskip.)

Widgets live in `lib/shared/widgets/ps_*.dart`; their tests in
`test/shared/widgets/ps_*_test.dart`; goldens in `test/shared/widgets/goldens/*.png`.

## 2. Remaining widget queue (dependency order)
1. **PsButton** (primary = accent fill / secondary = glass / ghost = text-only; 50px, radius-md, scale-on-press 0.98) — unlocks LoginScreen
2. **PsTextField** (glass-thin bg, glass-border, radius-md, 50px; focus → accent-secondary border + glow) — unlocks LoginScreen + OnboardingScreen
3. **PsFilterPill**, **PsToggle**, **PsStatusBadge** (live/open/closed + pulsing dot), **PsStakePill**, **PsLiveDot** (1.6s pulse), **PsAvatar** (PsGradients.avatar circle)
4. **PsCard** (glass via `PsGlass.backdrop`, glassBorder, top highlight line, `PsElevation.e4`, optional 4px left accent-rail by state, scale 0.985 press), **PsListTile**, **PsMetric** (scoreboard: display number + micro label + top highlight; hero/full variants)
5. **PsGlassNav** (frosted top bar via `PsGlass.backdrop`, PsBrand + actions), **PsSheet** (glass-thick bg + 36×5 grabber), **PsTabBar** (floating glass; only if a screen needs it)

Component CSS recipes for each are in `docs/superpowers/mockups/v3-design-system/components.css`
(prefix `.ps-`); the spec doc §10 maps each `Ps*` widget → its `.ps-` source.

## 3. Established patterns (reuse verbatim)
- **One atomic commit per widget** = implementation + widget test + golden baseline. Subject: `feat(ui): PsX … (Design Polish Phase 2)`.
- **Golden generation:** `flutter test --update-goldens test/shared/widgets/ps_x_test.dart` (creates `goldens/ps_x.png`), then plain `flutter test` passes. Commit the PNG.
- **Glass everywhere uses `PsGlass.backdrop(blur)`** = `ImageFilter.compose(outer: ColorFilter.matrix(PsGlass.saturationMatrix), inner: ImageFilter.blur(...))`, wrapped in `BackdropFilter` + clipped to the rounded shape, over a translucent fill + 1px `PsColors.glassBorder`. Wrap glass layers in `RepaintBoundary`. `const` constructors throughout.
- **NO hardcoded literals** in widget code — every color/size/radius/duration via `tokens.dart`. **NO Material default widgets** in final UI.
- **Tests:** assert resolved token values (color/fontSize/spacing) + press behavior; golden for visual widgets. Wrap pumped widgets in `MaterialApp` (the test config handles fonts). Avoid `pumpAndSettle` on live-stream/animation-heavy trees (use bounded `pump()`; dispose timer-bearing widgets before test end).
- **Commit messages:** use a single-line `git commit -m "...(...)"` (parens OK in double quotes) OR `-F msgfile`; multi-line PowerShell here-strings with quotes/parens have repeatedly broken — avoid them.

## 4. Phase 3 — re-skin screens (after widgets), 1 atomic commit each
Order + mockup file:
1. `LoginScreen` (`features/auth/presentation/login_screen.dart`) — **no mockup**, build from system (Q1).
2. `OnboardingScreen` (`features/onboarding/presentation/onboarding_screen.dart`) — `onboarding-welcome.html`.
3. `ClubsListScreen` (`features/clubs/presentation/clubs_list_screen.dart`) — `player-clubs-list.html`.
4. `ClubDetailsScreen` (`features/clubs/presentation/club_details_screen.dart`, incl. join-waitlist sheet) — `player-club-details.html`; sheet via PsSheet+PsStakePill (Q2).
5. `PlayerHome` + my-waitlist banner (`features/home/presentation/player_home.dart`, `features/floor/presentation/my_waitlist_banner.dart`) — `my-status.html`.
6. `PitBossHome` (`features/home/presentation/pit_boss_home.dart`, incl. seat-picker) — `pit-boss-live-floor.html` (+ `pit-boss-table-detail.html`).
Update existing screen widget tests to keep them green. Read each mockup HTML before re-skinning.

## 5. Phase 4 — build + deploy
`cd pokerspot; flutter build web --dart-define-from-file=env-dev.json` then
`firebase deploy --only hosting`; confirm https://pokerspot.web.app HTTP 200.
**Disk:** C: was critically full; freed to ~4.6 GB (deleted Roblox + npm cache).
That's enough for builds, but watch it — if `ENOSPC`, `flutter clean` frees ~200MB
and Aleksandre must free more (system caches are harness-protected; see the
disk-cleanup exchange — only Roblox was a game; the 11.9 GB `Packages\Claude` is
this app, do not touch). Firebase token may need `firebase login --reauth` (ask Aleksandre; do not reauth yourself).

## 6. Active decisions
- **Q1** LoginScreen: built from the system (no mockup exists).
- **Q2** Join-waitlist sheet + seat-picker: `PsSheet` + `PsStakePill`/seat-chips.
- **Q3** Saturation: `ColorFilter.matrix` via `PsGlass.saturationMatrix` / `PsGlass.backdrop()` — centralized, applied to EVERY glass surface (accepted small per-frame GPU cost for 100% parity; NOT blur-only).
- **Q4** Golden tests committed to the repo.

## 7. After Design Polish
Aleksandre will paste a **Plans 5-6-7 autonomous execution prompt** (he has it prepared):
Plan 5 = Pit Boss rich UI + "call next" notifications; Plan 6 = chat; Plan 7 =
Cloud Functions + custom claims + security rules (Blaze). Reservations also still
owe a mini-plan. Don't start these until he provides the prompt.

## 8. Standing orders (unchanged)
- No hardcoded literals; no Material defaults in final UI; 60fps (RepaintBoundary + const).
- Existing tests stay green; add goldens where feasible; one atomic commit per widget/screen.
- `flutter analyze` clean after every commit; full `flutter test` green after every commit.
- STOP only on genuine architectural ambiguity. Reply in Georgian (code/paths/commands as literals). Don't use AskUserQuestion — ask inline. (See auto-memory.)

---
**Fresh session: start at queue item #1 (PsButton).** Read `docs/design-system/liquid-sport.md` §10 + `components.css` `.ps-btn` first, then implement PsButton + test + golden, commit, and continue down §2.

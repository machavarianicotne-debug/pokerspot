# Liquid Sport — Design System Spec (Design Polish Pass, Phase 1)

> Extracted from the canonical mockups in `docs/superpowers/mockups/v3-design-system/`
> (`tokens.css` = single source of truth, `components.css` = component recipes) plus the
> per-screen HTML. Goal: 100% visual parity between the Flutter app and these mockups.
> Audited through **apple-hig-designer** (typography hierarchy, 8pt grid, motion curves,
> 44–50px touch targets) and **liquid-glass** (frosted/refractive material on the
> navigation/control layer only — never on content text).
>
> **STOP-for-approval doc.** No widget code until approved.

---

## 0. Source mockups → app screens (+ GAPS)

| App screen (Plans 1–4) | Mockup file | Status |
|---|---|---|
| `OnboardingScreen` | `onboarding-welcome.html` | ✅ exists (confirm name/lang form fields in Phase 3) |
| `ClubsListScreen` | `player-clubs-list.html` (+ chosen `player-clubs-list/variant-3.html`) | ✅ |
| `ClubDetailsScreen` | `player-club-details.html` | ✅ |
| `PlayerHome` / my-waitlist banner | `my-status.html` | ✅ |
| `PitBossHome` (waitlist + seated) | `pit-boss-live-floor.html` (+ `pit-boss-table-detail.html`) | ✅ |
| **`LoginScreen` (phone OTP)** | — | ⚠️ **GAP — no mockup.** Will design from the system (PsScaffold + PsBrand + PsTextField + PsButton) consistent with onboarding. Needs sign-off. |
| Join-waitlist sheet (club details) | — | ⚠️ **GAP** — no dedicated mockup. Will use `PsSheet` + `PsStakePill` rows. |
| Seat-picker (pit boss) | `pit-boss-table-detail.html` / `pit-boss-new-game.html` (partial reference) | ⚠️ partial — confirm in Phase 3. |

Out of scope now (future-plan mockups, listed for token/component completeness only):
`player-club-chat`, `pit-boss-chat-thread`, `pit-boss-inbox/stats/settings/new-game`,
all `super-admin-*`, `reservation-flow`, `profile`, `theme-playground`.

> Note: mockups render inside a `.ps-phone` 390×844 device frame with a 52px bezel.
> That frame is a **mockup artifact** — the Flutter app is full-screen; we reproduce the
> *content* (gradient background, glass nav, cards), not the simulated phone shell.

---

## 1. Color (from `tokens.css`)

| Token | Hex / value | Role |
|---|---|---|
| accent-primary | `#C6FF3A` | electric lime — live numbers, primary CTA fill |
| accent-secondary | `#34E3FF` | cyan — secondary highlights, focus ring, toggle-on |
| on-accent | `#06241A` | text/icon on an accent fill |
| status-live | `#FF4D57` | LIVE badge (also `status-full`) |
| status-open | `#FFB02E` | open, no games yet |
| status-closed | `#56646A` | closed / off-hours |
| bg-0 | `#04151A` | deep base |
| bg-1 | `#062A2C` | upper base |
| bg-bloom-a | `rgba(52,227,255,0.16)` | cyan radial bloom (background) |
| bg-bloom-b | `rgba(198,255,58,0.12)` | lime radial bloom (background) |
| text | `#ECFBFF` | primary text |
| text-muted | `rgba(236,251,255,0.56)` | secondary text |
| text-faint | `rgba(236,251,255,0.32)` | tertiary / labels |

Glass materials: `glass-bg-thin rgba(255,255,255,0.05)`, `glass-bg-regular .085`,
`glass-bg-thick .14`, `glass-border rgba(255,255,255,0.11)`, `glass-highlight
rgba(255,255,255,0.30)` (top specular line).

(Alternate themes `dark-casino` / `gold` exist in tokens.css — out of scope, but the
token indirection means swapping is a later one-file change.)

## 2. Typography (from `tokens.css` + usage in `components.css`)

Families: display `-apple-system, "SF Pro Display", "Inter"`, body `… "SF Pro Text" …`.
Flutter today loads **Inter** via GoogleFonts (SF Pro isn't licensable for web) — keep Inter
as the concrete family; it's the mockup's declared fallback.

| Role token | px | Used for |
|---|---|---|
| display-1 | 42 | hero metric numbers, brand on auth |
| display-2 | 30 | large secondary numbers |
| title | 22 | screen titles, brand wordmark |
| headline | 18 | club name, button label, input text |
| body | 15 | default |
| subhead | 13 | secondary labels |
| caption | 12 | chips |
| micro | 10 | overlines / badge labels (uppercase) |

Weights: regular 400, medium 600, bold 800, black 900.
Tracking: tight −1, snug −0.4, normal 0, wide 0.8, overline 1.2. Numbers use
tabular figures. Brand is **italic black** with tight tracking.

## 3. Spacing — 8pt grid
`s1 4 · s2 8 · s3 12 · s4 16 · s5 20 · s6 24 · s8 32 · s10 40 · s12 48`. Screen pad = s4.
Touch targets: buttons/inputs **50px** min-height (exceeds HIG 44pt — keep).

## 4. Radii (concentric)
`sm 10 · md 14 · lg 20 · xl 26 · full 999`. Buttons/inputs/metrics = md; cards = lg;
tab bar = xl; pills/badges/toggles = full (sm for status-badge).

## 5. Elevation / shadow (from `tokens.css`)
```
elevation-1: 0 2px 6px -3px rgba(0,0,0,.5)
elevation-2: 0 8px 18px -10px rgba(0,0,0,.6)
elevation-3: 0 16px 30px -18px rgba(0,0,0,.7)
elevation-4: 0 22px 40px -22px rgba(0,0,0,.85)   ← cards, tab bar
elevation-5: 0 30px 60px -26px rgba(0,0,0,.92)
inset-highlight: 0 1px 0 rgba(255,255,255,.30) inset   ← top sheen on glass
```
Flutter: negative-spread CSS shadows → `BoxShadow(offset, blurRadius, spreadRadius:
negative, color)`. The inset top-highlight has no direct `BoxShadow` inset → render via a
1px top gradient line (CustomPainter / a top `Container` with a horizontal highlight
gradient), as `ps-metric::before` does.

## 6. Gradients
- **Background** (PsScaffold): two radial blooms over a vertical base —
  `radial(100% 55% at 20% 0%, bloom-a→transparent)`, `radial(90% 50% at 95% 12%,
  bloom-b→transparent)`, `linear(180deg, bg-1→bg-0)`.
- **Avatar**: `linear(135deg, accent-secondary → #0A84FF)`.
- **Metric top line / glass highlight**: `linear(90deg, transparent → glass-highlight →
  transparent)`.
Flutter: `BoxDecoration(gradient:)` for linear; stacked `RadialGradient`s (or a
CustomPainter) for the blooms.

## 7. Glass material (Liquid Glass, per the liquid-glass skill — control layer only)
Recipe = translucent white bg + `backdrop-filter: blur(B) saturate(170%)` + 1px
`glass-border` + top inset-highlight. Tiers: thin (blur 16, bg .05), regular (blur 22,
bg .085), thick (blur 30, bg .14). **Flutter:** `BackdropFilter(filter:
ImageFilter.blur(sigmaX/Y))` clipped to the rounded shape, over a translucent fill +
border; `saturate` has no Flutter filter → approximate with a subtle
`ColorFilter.matrix` saturation or accept blur-only (note as a known Skia-vs-browser
delta). Glass is used on: nav bar, cards, inputs, pills, toggles, tab bar, sheets —
**never on body text/content**.

## 8. Motion (from `tokens.css` + `components.css`)
Durations: fast 160 · normal 280 · slow 520 ms.
Eases: standard `cubic-bezier(.22,.61,.36,1)` (= existing `PsMotion.ease`),
decelerate `(0,0,.2,1)`, accelerate `(.4,0,1,1)`.
- **Press feedback:** `scale(0.98)` (cards 0.985, pills 0.96), 160ms standard.
- **Entrance (`ps-rise`):** opacity 0→1 + translateY 16→0, 520ms standard, staggered
  delays 0.04/0.10/0.16/0.22/0.28s for the first 5 children.
- **Live dot (`ps-pulse`):** expanding ring box-shadow, 1.6s infinite.
- Respect reduced-motion (disable animations).

---

## 9. Token gap analysis — `tokens.css` vs current `lib/core/theme/tokens.dart`

Present in tokens.dart: accentPrimary/Secondary, onAccent, statusLive/Open/Closed,
bg0/bg1, text/textMuted/textFaint, glassThin/Regular/Border, spacing s1–s12, radii
sm/md/lg/xl/full, type display1/display2/title/headline/body/subhead/caption/micro,
motion fast/normal/slow + one ease.

**Missing → propose adding to tokens.dart:**
- `PsColors`: `statusFull` (#FF4D57), `bgBloomA`, `bgBloomB`, `glassThick` (.14),
  `glassHighlight` (.30).
- `PsGlass` (new): `blurThin 16`, `blurRegular 22`, `blurThick 30`, `saturate 1.70`.
- `PsType`: `fontWeight` constants (regular 400 / medium 600 / bold 800 / black 900) and
  `tracking` constants (tight −1, snug −0.4, normal 0, wide 0.8, overline 1.2).
- `PsRadii`: already complete.
- `PsElevation` (new): `e1…e5` as `List<BoxShadow>` + `insetHighlight` recipe helper.
- `PsGradients` (new): `background` (blooms), `avatar`, `glassHighlightLine`.
- `PsMotion`: add `easeDecelerate`, `easeAccelerate`.
- `PsLayout` (new): `screenPad` = s4 (max-pane width already handled by `CenteredPane`).

No widget may use a raw `Color(0xFF…)` / numeric literal — everything routes through these.

---

## 10. Proposed custom widget library (`lib/shared/widgets/ps_*.dart`)

Each is a thin, token-driven Liquid Sport primitive. "vs Material" = why it's not the
stock widget.

| Widget | Source (`components.css`) | Liquid Sport specifics / vs Material |
|---|---|---|
| `PsScaffold` | `body` + `.ps-phone` bg | Scaffold with the radial-bloom + linear gradient background painted behind content. vs `Scaffold`: no flat color; gradient + safe-area aware. |
| `PsGlassNav` (app-bar) | `.ps-glass-nav`, `.ps-brand` | Frosted `BackdropFilter` top bar, `PsBrand` leading + action slots. vs `AppBar`: no Material elevation line/ripple; glass + italic brand. |
| `PsBrand` | `.ps-brand` | Italic black wordmark, accent-colored span. |
| `PsCard` | `.ps-card` (+ `.accent-rail`) | Glass (blur+saturate) + border + inset-highlight + elevation-4 + optional 4px left accent-rail (state color) + `scale(0.985)` press. vs `Card`: glass not solid; accent-rail; spring press. |
| `PsButton` (`.primary`/`.secondary`/`.ghost`) | `.ps-btn--primary/secondary` | primary = accent fill + on-accent text; secondary = glass; **ghost = new** text-only variant. 50px, radius-md, `scale(0.98)` spring. vs `FilledButton`: no ripple/MaterialState; lime fill; spring. |
| `PsTextField` | `.ps-input` | glass-thin bg, glass-border, radius-md, 50px; focus → accent-secondary border + glow ring. vs `TextField`: no underline/Material fill; glass + glow. |
| `PsFilterPill` | `.ps-filter-pill` | glass pill, active = accent fill; `scale(0.96)`. |
| `PsToggle` | `.ps-toggle` | custom 42×25 track + 19px knob, on = accent-secondary. vs `Switch`: exact track sizing/colors. |
| `PsStatusBadge` | `.ps-status-badge` | live/open/closed; micro uppercase; live variant embeds pulsing `PsLiveDot`. |
| `PsStakePill` | `.ps-stake-pill` | glass pill; variant/type span in accent. |
| `PsMetric` | `.ps-metric` | scoreboard block: big tabular display number + micro label + top highlight line; hero/full variants. |
| `PsOverline` | `.ps-overline` | micro, black, uppercase, overline tracking, faint. |
| `PsLiveDot` | `.ps-live-dot` | pulsing ring (1.6s) via `AnimatedBuilder`/`CustomPainter`. |
| `PsSheet` | (mockup sheets) | bottom sheet: glass-thick bg + grabber (36×5) + rounded-top; hosts join/seat pickers. vs `showModalBottomSheet`: glass background + grabber. |
| `PsListTile` | card rows in screens | glass-card row for clubs / waitlist / sessions (leading/title/subtitle/trailing) replacing Material `ListTile`. |
| `PsAvatar` | `.ps-avatar` | gradient circle, initials. |
| `PsTabBar` | `.ps-tabbar` | floating glass tab bar (available; only if a screen needs bottom tabs). |
| `PsRise` | `.ps-rise` | entrance wrapper: opacity+translateY rise with index-based stagger; honors reduced-motion. |

Performance: each glass layer wrapped in `RepaintBoundary`; `const` constructors
throughout; `BackdropFilter` count minimized (group where possible — mirrors the
liquid-glass "share a container" guidance).

## 11. Testing
- Per widget: a widget test asserting token application (resolved color / fontSize /
  padding) + interaction (press scale) where applicable.
- **Golden tests**: set up `flutter_test` goldens (`matchesGoldenFile`) per widget +
  per re-skinned screen, with `flutter test --update-goldens` to capture baselines.
  Goldens are platform-sensitive (Skia) — commit them as the Flutter baseline, noted as
  the source of truth for regressions (not pixel-identical to the browser mockup).
- Existing 97 pass + 3 skip stay green.

## 12. Execution structure (Phases 2–4, per writing-plans)
- **Phase 2:** extend `tokens.dart` (§9) → one commit; then one atomic commit per
  `Ps*` widget (impl + widget test + golden), least-dependent first
  (tokens → PsRise/PsOverline/PsLiveDot → PsBrand/PsAvatar → PsButton/PsTextField/
  PsFilterPill/PsToggle/PsStatusBadge/PsStakePill → PsCard/PsListTile/PsMetric →
  PsGlassNav/PsScaffold/PsSheet/PsTabBar).
- **Phase 3:** re-skin screens in dependency order (Login → Onboarding → ClubsList →
  ClubDetails → PlayerHome → PitBossHome), one atomic commit each; update existing
  widget tests to stay green.
- **Phase 4:** `flutter build web` + `firebase deploy` + confirm HTTP 200.
- Gate after every commit: `flutter analyze` clean + full test green.

## 13. Open items needing sign-off
1. **LoginScreen has no mockup** — approve designing it from the system (auth layout like
   onboarding: PsScaffold + centered PsBrand + PsTextField + primary PsButton)?
2. **Join-waitlist sheet & seat-picker** have no dedicated mockup — approve `PsSheet` +
   `PsStakePill`/seat-chip composition consistent with the system?
3. **`saturate(170%)`** has no native Flutter backdrop filter — accept blur-only glass (a
   minor, inherent Skia-vs-browser delta) or invest in a `ColorFilter.matrix` saturation
   pass?
4. **Goldens**: set up golden testing now (adds baseline PNGs to the repo)?
</content>

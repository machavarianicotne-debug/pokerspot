# PokerSpot Design System — Variant 3 "Liquid Sport"

A token-driven design system. **Every visual decision lives in `tokens.css`.**
Components (`components.css`) and screens contain *zero* literal colors, sizes,
or fonts — they only reference tokens. Change a token once → the whole app
re-skins. This CSS system mirrors the Flutter `lib/core/theme/` 1:1, so the same
edits apply there later.

## Files

| File | Role | You edit it when… |
|------|------|-------------------|
| `tokens.css` | Single source of truth: colors, type, spacing, radii, shadows, motion, glass, **themes** | changing *any* visual value |
| `components.css` | Reusable atoms (`.ps-card`, `.ps-status-badge`, `.ps-btn`, …) referencing tokens | adding/altering a component's structure |
| `player-clubs-list.html` | Screen 1 (home) — layout only | changing that screen's layout |
| `player-club-details.html` | Screen 2 (club detail) — layout only | changing that screen's layout |
| `theme-playground.html` | Both screens side-by-side + live theme switcher | demoing changeability |

Open `theme-playground.html` to **see both screens re-skin together** when you
switch themes — that is the changeability test, live.

## How to change things (the whole point)

### Change the accent color (lime → anything)
Edit **one** variable in `tokens.css`:
```css
--color-accent-primary: #c6ff3a;   /* → #ffcf4a for gold, #ff5a5f for red, … */
```
Every live number, primary button, active filter, accent rail, and tab-bar
highlight updates across **both** screens. No other edit.

### Change the whole color scheme
These are the variables that define the mood — edit these and you've re-themed:
```css
--color-accent-primary      /* primary highlights / numbers / CTAs */
--color-accent-secondary    /* secondary highlights / focus */
--color-bg-0, --color-bg-1  /* background gradient */
--color-text                /* foreground */
```
(Status colors `--color-status-live/open/closed` and glass tints round it out.)

### Switch design *direction* (Liquid Sport → Dark Casino → …)
Two ways, both one-touch:

1. **Flip a theme** — set `data-theme` on `<html>`:
   ```html
   <html data-theme="dark-casino">   <!-- or "gold", or remove for Liquid Sport -->
   ```
   The alternate values live in the `[data-theme="…"]` blocks at the bottom of
   `tokens.css`.

2. **Replace the `:root` block** — swap the default token values wholesale.

### Concrete diff — Liquid Sport → Dark Casino Glass
Only these change (everything else inherits):
```css
--color-accent-primary:   #c6ff3a → #e8c77a   /* lime → gold */
--color-accent-secondary: #34e3ff → #1fa971   /* cyan → felt green */
--color-on-accent:        #06241a → #0a0c0b
--color-status-live:      #ff4d57 → #2fe08a   /* red LIVE → green LIVE */
--color-bg-0:             #04151a → #07090a
--color-bg-1:             #062a2c → #0c1011
--color-bg-bloom-a/-b:    teal/lime glow → green/gold glow
--color-text(+muted/faint): icy white → warm cream
```
That is ~10 lines for a full mood change — no component or screen edits.

### Change the display font (Inter → Newsreader, etc.)
```css
--font-family-display: "Newsreader", Georgia, serif;   /* titles & big numbers */
--font-family-body:    -apple-system, "Inter", sans-serif;
```

### Change spacing, radii, motion
- Density: edit the `--space-*` scale (8pt grid).
- Roundness: edit `--radius-*` (concentric).
- Feel of motion: edit `--duration-*` and `--ease-*`.

## Token groups in `tokens.css`

`accent` · `status` · `surfaces/background` · `text` · `glass materials`
(thin/regular/thick blur + tints) · `typography` (families, type scale, weights,
tracking) · `spacing` (8pt) · `radii` · `elevation` · `motion` · `layout`.

All names are human-readable (`--color-accent-primary`, `--type-display-1`,
`--space-4`) — never `--c1` / `--s2`.

## Flutter parity

| CSS here | Flutter later |
|----------|---------------|
| `tokens.css` `:root` vars | `lib/core/theme/tokens.dart` |
| `[data-theme]` blocks | `ThemeData` variants / theme extension |
| `components.css` `.ps-*` | `lib/core/theme/components/*` widgets |
| screen `.html` layout | feature `presentation/` widgets |

Same names, same structure — the prototype *is* the spec for the Dart theme.

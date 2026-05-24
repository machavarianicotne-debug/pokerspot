# PokerSpot — Full-App Spec (100% mockup parity)

> **Single source of truth:** `docs/superpowers/mockups/v3-design-system/` (Liquid
> Sport). **Liquid Sport is the priority theme** — `lib/core/theme/tokens.dart`
> already ports its `:root` 1:1; the `dark-casino`/`gold` `[data-theme]` variants
> are out of scope. This spec audits the running Flutter app against every mockup
> file and defines the rebuild wave plan.

## 1. Canonical source files (all 27 read)
**Design system:** `tokens.css`, `components.css`, `README.md`, `index.html`
(gallery), `theme-playground.html` (dev tool — not an app screen), `store.js`
(mockup localStorage demo helper — not shipped).

**Player (7):** `onboarding-welcome`, `player-clubs-list`, `player-club-details`,
`player-club-chat`, `reservation-flow`, `my-status`, `profile`.

**Pit Boss (7):** `pit-boss-live-floor`, `pit-boss-table-detail`,
`pit-boss-new-game`, `pit-boss-inbox`, `pit-boss-chat-thread`, `pit-boss-stats`,
`pit-boss-settings`.

**Super Admin (7):** `super-admin-dashboard`, `super-admin-clubs-crud`,
`super-admin-assign-pitboss`, `super-admin-users`, `super-admin-observe-club`,
`super-admin-observe-table`, `super-admin-settings`.

> Read in full this pass: all design-system files + Player set + chat + Pit Boss
> floor/table-detail/new-game/stats + Super Admin dashboard/clubs/users/assign-PB.
> Characterised from `index.html` descriptions + shared patterns (settings =
> `profile` group pattern; inbox = thread list; chat-thread = `player-club-chat`;
> observe-* = read-only Pit Boss floor/table): `pit-boss-settings`,
> `pit-boss-inbox`, `pit-boss-chat-thread`, `super-admin-observe-club/table`,
> `super-admin-settings`. These are confirmed before their wave builds.

## 2. Canonical navigation (bottom `PsTabBar` per role)
- **Player:** Clubs · Activity · Profile.
- **Pit Boss:** Floor · Inbox · Stats · Settings  *(4 tabs — current app has Floor/Tables/Profile; mockup replaces Tables-tab with Inbox/Stats/Settings and folds table management INTO Floor → Table Detail).*
- **Super Admin:** Dashboard · Clubs · Pit Bosses · Users · Settings  *(5 tabs — current app has Overview/Clubs/Users/Profile).*

## 3. Per-screen audit (mockup → current Flutter)
| Screen | Current state | Gap to 100% |
|---|---|---|
| onboarding-welcome | ✅ built, close | minor: hero orb/title parity OK |
| player-clubs-list | ✅ built | mockup shows **live metrics** (open seats/stakes/waitlist) + status badge + filter pills (city / NLH·PLO / OPEN toggle) + livecount in nav. Needs floor-aggregate data. |
| player-club-details | ✅ simplified | add: chat-entry row, **Reserve** bar, per-stake **game cards** w/ metrics + join states. |
| player-club-chat | ❌ missing | full chat (bubbles in/out, composer, typing). New `messages` collection. |
| reservation-flow | ❌ missing | stake choice + 30-min instant-hold + success overlay. New `reservations`. |
| my-status | 🟡 partial (Activity) | add: **now-playing** card w/ live timer, reservations section, **playtime stats** (today/lifetime, by-club bars, 7-day bars). |
| profile | 🟡 partial | add: notification toggles, **edit display name**, **delete account**, language mini-picker. |
| pit-boss-live-floor | 🟡 simplified (waitlist+sessions) | mockup is **table-centric**: numbered table cards w/ mini seat dots + counts, summary line, New game / New table actions. |
| pit-boss-table-detail | 🟡 simplified seat grid | mockup: **oval felt** seat map, per-seat live timers + >8h warn, smart seat-search sheet (registered/walk-in/call #1), editable blinds/avg/min (mirrors same-stake tables), shared waitlist + reservations, take-break/close. |
| pit-boss-new-game | ❌ missing | type/blinds(+custom)/currency/min/avg/tables stepper → opens game. |
| pit-boss-inbox | ❌ missing | chat thread list + unread badges. |
| pit-boss-chat-thread | ❌ missing | 1-on-1 thread (= player chat, staff side). |
| pit-boss-stats | ❌ missing | registered/walk-in leaderboard + player detail. |
| pit-boss-settings | ❌ missing | availability/notifications/reset (settings groups). |
| super-admin-dashboard | 🟡 (Overview) | network stat grid, club mini-cards (live dots) → observe, today, 7-day trend, quick actions. |
| super-admin-clubs-crud | 🟡 (clubs CRUD) | richer form: currency, hours (24/7 toggle), languages, logo, **FAQ list**, soft-delete. |
| super-admin-assign-pitboss | 🟡 (in Users) | dedicated tab: active assignments + pending invites + assign-by-phone. |
| super-admin-users | ✅ close | add detail overlay (sessions/playtime, assignment history), sort, role filter seg. |
| super-admin-observe-club | ❌ missing | read-only club floor view. |
| super-admin-observe-table | ❌ missing | read-only table view. |
| super-admin-settings | ❌ missing | app-wide rules/flags/health (settings groups). |

## 4. New `Ps*` atoms to extract (reusable)
`PsSeatMap` (oval felt + positioned seats), `PsBarChart` (7-day / playtime bars),
`PsSegmented` (segmented control — type/currency/filter), `PsStepper`
(±number), `PsChatBubble` + `PsComposer`, `PsSettingsGroup`/`PsSettingsRow`
(grouped glass rows + chevron/toggle/value), `PsCountdown` (live mm:ss),
`PsMoneyField`, `PsFab`. Reuse existing: PsScaffold, PsGlassNav, PsTabBar, PsCard,
PsButton, PsTextField, PsToggle, PsFilterPill, PsStatusBadge, PsStakePill,
PsAvatar, PsListTile, PsMetric, PsLiveDot, PsBrand, PsOverline, PsSheet.

## 5. Data-model deltas (new collections / fields)
- **`reservations/{id}`** (new): `clubId`, `playerUid`, `playerName`, stake fields,
  `status` (held|arrived|expired|cancelled), `heldUntil` (serverTs+30m), `createdAt`.
  Function to auto-expire (mirror waitlist expiry).
- **`messages/{clubId_playerUid}/messages/{msgId}`** (new): `senderUid`, `senderRole`,
  `text`, `at`; thread doc tracks `lastMessage`, `unread` counts. Rules: club PB + that player + admin.
- **`clubs/{id}`** new fields: `currency`, `languages[]`, `open24`, `hoursOpen`/`hoursClose`, `faq[]` ({q,a}), `pitBossUid?`.
- **tables** new fields: `avgStack?`, `minBuyIn?`, `onBreak`.
- **sessions** add `registered:bool` (vs walk-in), keep existing.
- **`users`** add `notif` map (seatCalled/reservation/clubNews), `lastSeenAt`.
- **`pitboss_invites/{id}`** (new): `phone`, `clubId`, `status` (pending|claimed) — claimed on first sign-in of that phone.

## 6. Wave plan (order; atomic commits within; 1 deploy per wave)
1. **Wave 0 — atoms:** extract the new `Ps*` atoms (§4) with tests + goldens.
2. **Wave 1 — Pit Boss floor:** table-centric live-floor + table-detail (PsSeatMap, seat search, editable stakes, shared waitlist/reservations) + new-game.
3. **Wave 2 — Player:** clubs-list metrics + filters, club-details (game cards, reserve, chat entry), reservation-flow, my-status (now-playing + stats), profile (toggles/edit/delete).
4. **Wave 3 — Chat:** `messages` model + Cloud Function fan-out; player-club-chat, pit-boss-inbox, pit-boss-chat-thread.
5. **Wave 4 — Pit Boss extras:** stats, settings.
6. **Wave 5 — Super Admin:** dashboard, clubs-CRUD (FAQ/currency/hours/langs), assign-PB (+invites), users detail, observe-club/table, settings.
7. **Wave 6 — backend hardening:** rules for new collections, reservation/expiry functions, final deploy.

## 7. Honest substitutions / deferred (surfaced, not dropped)
- **Web target only.** Native Android/iOS deferred (per orders).
- **Push** stays skipped until VAPID key (Plan 7-C). Mockup "gets push" labels render but no device token yet.
- **Logo/photo upload** (clubs CRUD, profile avatar image): no Firebase Storage wired → keep gradient-orb initials + `photoUrl` string field; file upload deferred.
- **Sounds/haptics:** deferred per orders.
- **`theme-playground` / live theme switch:** dev tool — not an app screen; Liquid Sport is fixed.
- **Charts** (`PsBarChart`): CSS gradient bars → Flutter custom-painted bars (close approximation; no chart lib).
- **Oval seat geometry:** trig-positioned seats on a rounded felt (faithful); drag-to-seat gesture deferred.
- **Smart seat-search** matches against the real `users` collection (registered) + free-text walk-in; "member since" uses `users.createdAt`.

## 8. Standing constraints
Atomic commits · `flutter analyze` clean + `flutter test` green per commit ·
monotonic test count · l10n en/ka/ru + `flutter gen-l10n` · no Material defaults ·
1 `firebase deploy` per wave · honest substitution notes in commits.

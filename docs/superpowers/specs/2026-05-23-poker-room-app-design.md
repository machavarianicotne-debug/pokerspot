# Tbilisi Poker Rooms App — MVP Design Spec

**Date:** 2026-05-23
**Status:** Approved for planning
**Author:** Owner + Claude (brainstorming session)

---

## 1. Overview

A free mobile app uniting up to ~20 poker clubs in the Tbilisi market into one
real-time marketplace. Players see which games are running where and join
waitlists/reservations; club floor managers ("Pit Boss") run their club's floor
live; the owner ("Super Admin") manages clubs and sees activity across all of
them.

**One Flutter codebase, one Play Store entry, three roles** — UI is selected by
the signed-in user's role. This is **not** a multi-flavor / multi-target build;
it is a single app with role-based routing.

### Goals

- Players find live action and reserve a seat without phoning around.
- Pit Bosses manage tables, waitlists, and reservations in real time from the app.
- Owner manages the club network and sees what's happening.
- Ship a production MVP for a 1–2 club Tbilisi pilot within 8–12 weeks.

### Non-goals (MVP)

See §14 (v2 backlog). Notably: no iOS at launch, no per-seat player identity,
no deep analytics, no multi-day reservations.

---

## 2. Roles

| Role | How obtained | Scope |
|------|-------------|-------|
| **Player** (default) | Phone OTP self sign-up | All clubs (read), own waitlists/reservations |
| **Pit Boss** | Assigned by Super Admin (by phone) | One club (MVP), full floor management |
| **Super Admin** | Manually seeded (owner) | All clubs, CRUD + assignment + analytics |

- A club may have **multiple** Pit Bosses (shifts). A Pit Boss is bound to **one**
  club in MVP (multi-club → v2).
- Roles are enforced via **Firebase Auth custom claims** (`role`, `assignedClubId`),
  set server-side by Cloud Functions. Roles are **never** writable by clients.
  The role is also mirrored into the user's Firestore doc for UI convenience.

---

## 3. Constraints

- **Windows-only development, no Mac.** iOS cannot be built/signed/deployed
  locally. → **Android-first** launch; iOS deferred to v2 via cloud Mac CI
  (Codemagic free tier / GitHub Actions macOS runners) or after acquiring a Mac.
- **Budget: minimal, but not $0.** Confirmed acceptable:
  - **Firebase Blaze (pay-as-you-go) plan is required** (Cloud Functions need it).
    Blaze has a large free monthly allowance; a credit card is required. A
    **budget alert** will be configured.
  - **Phone OTP SMS** costs money beyond a small free quota — low for a 1–2 club
    pilot (a few USD), not zero.
  - **FCM push** is free/unlimited.
- **Firestore free read ceiling (~50K reads/day)** is mitigated by the
  overview + drill-down strategy (§5).
- **Languages:** Georgian (ka), English (en), Russian (ru).

---

## 4. Architecture

```
┌─────────────────────────── Flutter app (Android-first) ───────────────────────────┐
│  Auth (phone OTP)  →  role from custom claims  →  role-based shell                  │
│   ├── Player UI        ├── Pit Boss UI (Live Floor)     └── Super Admin UI          │
└────────────────────────────────────────────────────────────────────────────────────┘
                 │ Firestore listeners (scoped)            │ callable functions
                 ▼                                          ▼
┌──────────────────────────────── Firebase ────────────────────────────────────────┐
│  Auth (phone OTP, custom claims)                                                   │
│  Firestore (real-time)   clubs / games / tables / waitlist / reservations          │
│                          users / pitBossAssignments / clubOverviews (denormalized) │
│  Cloud Functions (Blaze): aggregation · push · reservation expiry · claims         │
│  Cloud Messaging (FCM): push notifications                                         │
└────────────────────────────────────────────────────────────────────────────────────┘
```

### Real-time strategy (cost control)

- **Player club list** subscribes only to the small, denormalized
  `clubOverviews` collection (counts only). ≈1 read per club + change deltas.
- **Player club detail** attaches detailed listeners (games/waitlist) for that
  one club **only while the screen is open**, and detaches on close.
- **Pit Boss** has full real-time read/write on **their own club only**.
- All writes are **optimistic** to Firestore; listeners reflect changes instantly.
- A Cloud Function recomputes `clubOverviews` whenever a table/waitlist changes.

---

## 5. Domain & Data Model

### Domain logic (decisions)

- A club runs several **games**, each defined by a **stake** (type + blinds),
  e.g. `1/3 NLH`, `5/5 PLO`.
- A game has **one or more tables**.
- **Waitlist is per-stake (per game), shared across that game's tables.** A
  player waits for a stake and is seated at whichever physical table opens first.
- A player may sit on **multiple waitlists simultaneously**, including different
  stakes in the **same** club ("ready for 1/3 OR 5/5, whichever opens first").
- **On `seated`**, the player's other active (`waiting`/`called`) waitlist
  entries **in the same club** are auto-cancelled. (Cross-club not handled — rare.)
  Being `called` does **not** cancel other entries.
- Pit Boss **manual override**: may seat a specific person directly (VIP/regular)
  without consuming waitlist #1; this does not reorder the queue.
- **Seats:** tracked as a count (`seatedCount` / `maxSeats`, default 9). The UI
  renders N seats (filled-first) for a pro feel, but **no per-seat player identity**
  is stored — the Pit Boss physically knows who is who. Open seats for a stake
  = Σ over open tables of `(maxSeats − seatedCount)`.

### Firestore collections

```
users/{uid}
  phone (E.164)  displayName  role(player|pitboss|superadmin)
  assignedClubId(nullable)  fcmTokens[]  lang(ka|en|ru)  createdAt  updatedAt

pitBossAssignments/{phoneE164}        # pending assignment applied on first sign-in
  clubId  assignedBy(uid)  createdAt

clubs/{clubId}
  name  city  address  phone  openingHours  geo(GeoPoint, optional, v2 map)
  languages[]  status(active|inactive)  photoUrl(logo)  createdAt  updatedAt
  # city: separate field ("Tbilisi", "Batumi") for sort & filter
  # phone: shown as tap-to-call on the Player club detail screen
  # openingHours: { mon:{open,close}, ... sun:{open,close}, is24_7:bool }

clubs/{clubId}/games/{gameId}
  type(NLH|PLO)  blinds(string e.g. "1/3")  buyInMin  averageStack(nullable)
  status(running|closed)  createdAt  updatedAt
  # blinds: runtime-editable by Pit Boss (per game); change reflects to players
  #   in real time; updatedAt tracks the change (internal, not shown in UI)
  # buyInMin > 0 required; NO buyInMax — Tbilisi format is uncapped
  # averageStack: Pit Boss manual estimate; players see the last value set;
  #   null ("—") until first set. updatedAt is server-side only, never shown in
  #   UI (no freshness / "x min ago" indicator)

clubs/{clubId}/tables/{tableId}        # top-level per club for club-global numbering
  tableNumber(int, unique per club, auto-incremented)  gameId(ref)
  maxSeats(default 9)  seatedCount  status(open|closed|breaking)  openedAt
  # tableNumber is club-global (not per game); + Add Table takes the next free
  #   number; a closed table frees its number

clubs/{clubId}/waitlist/{entryId}
  gameId  userId  displayName  position(float, for ordering & top-insert)
  status(waiting|called|seated|no_show|cancelled)  source(app|manual|reservation)
  joinedAt  calledAt  seatedAt

clubs/{clubId}/reservations/{resId}
  gameId  userId  displayName  partySize  reservedTime(timestamp, same-day)
  note  status(pending|accepted|rejected|arrived|expired|cancelled)
  createdAt  acceptedAt  expiresAt

chats/{chatId}                        # one private 1-on-1 thread per (club, player)
  clubId  playerId  pitBossId  lastMessage  lastMessageAt
  unreadByPlayer(int)  unreadByPitBoss(int)
chats/{chatId}/messages/{messageId}
  senderId  senderRole(player|pitboss)  text  createdAt  readAt

clubOverviews/{clubId}                # denormalized, Cloud-Function-maintained
  clubName  city  status  openingHours  photoUrl
  games: [ { gameId, type, blinds, openTables, openSeats, waitlistCount } ]
  updatedAt
  # client derives live status (🟢/🟡/⚫) from status + openingHours + games
```

**Versioning:** every document carries a `schemaVersion` (int) for phased
migrations — see §12.H.

**Waitlist ordering:** by `position` (float). New entries: `position = max+1`.
Reservation "Arrived" inserts at top: `position = currentMin − 1`. Manual seat of
a specific player does not change others' positions.

**Currency:** blinds/buy-ins displayed in GEL (assumption); stored as strings
(blinds) and numbers (buy-ins).

---

## 6. Core Flows

### Player

1. **Onboarding** — sign in with phone OTP. On **first** sign-in a **Welcome**
   screen captures **displayName (required)** + **language (ka/en/ru)**, then →
   Club list. `displayName` is later editable in Profile.
2. **Club list** — live overview per club: city, running games (stake), open
   seats, waitlist length, and a **live status badge**:
   - 🟢 **Live** — active + within opening hours + has open games
   - 🟡 **Open but empty** — active + within opening hours + no games opened yet
   - ⚫ **Closed** — off-hours, or left inactive by Super Admin

   Computed client-side from `status` + `openingHours` + current time + games.
   **Sort: Live → Open but empty → Closed**, then by city/name.
3. **Club detail** — header **info block** (logo, name, city, address,
   **tap-to-call phone**, opening hours), then a **Chat with Pit Boss** entry
   (private 1-on-1 Q&A — dress code, parking, "VIP table?"), then per-stake live
   cards. Each stake card shows type, **min buy-in (₾)**, **average stack (₾, or
   "—" if unset)**, tables, open seats, and waitlist count, with a **Join
   waitlist** action (and a **Reserve** action for the club). **Blinds update in
   real time** when the Pit Boss changes them. **Table numbers are internal**
   (Pit Boss only) — not shown to players. Tap-to-call opens the device dialer
   via `url_launcher` (small, MVP).
4. **Join waitlist** for a stake (multiple allowed); see own position; leave.
5. **Reserve** — same-day, choose stake + time + party size + note.
6. **My status** — own active waitlists & reservations.
7. **Profile** — edit displayName & language; **Logout**; **Delete Account**
   (see "Account deletion & logout" below).
8. **Push** — seat called, reservation accepted, reservation expiring.

### Pit Boss — "Live Floor" (own club)

UI is **table-centric** — the Pit Boss thinks per physical table, not per
section. Tabs: **Floor · Inbox · Settings**.

- **Live Floor** — a numbered card per **table** (club-global `tableNumber`,
  dominant): stake, seats X/9, blinds, avg stack, waitlist count. `+ New Game`
  and `+ New Table (same stake)`. Tap a table → table detail.
- **Table detail** — each table is a card with:
  - **Visual 9-seat grid** (oval). Tap **empty** seat → **Call #1** / **Seat #1**
    (from the stake's waitlist) / **Add walk-in**. Tap **occupied** seat →
    **player left** / **no-show + remove**. The grid is the interface (no counter
    mode).
  - **Blinds** (inline editable, **per game** — mirrors across same-stake tables,
    reflected to players in real time, 0.5s pulse), **average stack** (inline
    editable, per game), and min buy-in.
  - **Waitlist for the stake** (`[Call] [Seat] [✕]`, `+ walk-in`) and
    **Reservations** (`[Accept]`/`[✕]` → `Arrived` = top of waitlist) shown once
    per stake; sibling tables show "Shares waitlist with Table N".
  - `Close table` / `Take break`.
- **Table numbers** are **club-global and auto-incremented**; `+ Add Table` takes
  the next free number; a closed table frees its number.
- **Inbox** — list of private chat threads (one per player) with unread badges →
  1-on-1 chat thread.
- An evening starts with an **empty** club (no template auto-restore in MVP).

### Seating lifecycle

`waiting` → (Pit Boss **Call**) → `called` (+push) → (player arrives, Pit Boss
**Seat**) → `seated` → other same-club active entries auto-cancelled; or
(**No-show**) → `no_show` (manual, no auto-timer in MVP).

### Reservation lifecycle

`pending` → (Pit Boss **Accept**, +push) → `accepted` → (Pit Boss **Arrived**)
→ entry created at **top** of that stake's waitlist; or **auto-`expired`** if not
marked Arrived within **30 minutes of `reservedTime`** (grace window).
- `expiresAt = reservedTime + 30min`. Enforced by a Cloud Function timer
  (Cloud Tasks enqueued on accept, or a 1-minute scheduled sweep).

### Super Admin

- **Clubs list** — entry point to CRUD; shows all clubs with status.
- **Create / Edit club** form — all data-model fields: name, city, address,
  phone, openingHours, languages, photo (logo), geo (optional).
- **Deactivate club** — **soft delete** (`status = inactive`), never a hard delete.
- **Assign Pit Boss** — enter a phone number + choose a club → assign. If the
  user exists, claims are set immediately; otherwise a **pending assignment** is
  stored (applied on first sign-in).
- **Pending assignments** list — Pit Bosses assigned by phone who have not yet
  registered.
- **All-clubs live overview** — browse into any club as a **read-only observer**
  (see its live floor without write controls).

### Super Admin — Analytics (light, MVP)

- **Dashboard** — per-club counts: active players, open tables, waitlist size,
  pending reservations.
- **Daily aggregates** (selected day): total players seated, total reservations
  made, peak hour.
- **7-day trend** — small chart of player counts per day.
- **Source:** Firestore aggregation queries computed on read. **No separate
  analytics collection in MVP.** Deep analytics (rake, session length, player
  LTV) → v2.

### Account deletion & logout

- **Profile** exposes **Logout** and **Delete Account**.
- **Delete Account** (Player): confirmation dialog ("permanently deletes your
  data, cannot be undone") → Cloud Function `deleteAccount` deletes the user doc,
  cancels active waitlist entries, cancels reservations, removes FCM tokens, and
  deletes the Firebase Auth user → returns to Login. *(Required by Google Play
  for apps with accounts.)*
- A **Pit Boss** attempting delete is blocked with a warning ("contact Super
  Admin first"). **Super Admin** self-delete is disabled (separate manual owner
  procedure).

---

## 7. Cloud Functions (Blaze)

| Function | Trigger | Purpose |
|----------|---------|---------|
| `applyRoleOnSignIn` | Auth user create / first sign-in | Apply bootstrap owner → superadmin; apply `pitBossAssignments` by phone → set claims + user doc |
| `assignPitBoss` | Callable (superadmin) | Set role/claims for existing user, or create a pending assignment by phone |
| `recomputeOverview` | Firestore write on games/tables/waitlist | Rebuild `clubOverviews/{clubId}` |
| `notifySeatCalled` | Firestore: waitlist entry → `called` | FCM push to the called player |
| `notifyReservation` | Firestore: reservation → `accepted` / expiring | FCM push to player |
| `resolveSeated` | Firestore: waitlist entry → `seated` | Auto-cancel that user's other active same-club entries |
| `expireReservations` | Cloud Tasks (per reservation) or 1-min schedule | Set `expired` when past `expiresAt` without `arrived` |
| `deleteAccount` | Callable (account owner) | Delete user doc, cancel waitlist entries & reservations, remove FCM tokens, delete Auth user (Player only) |
| `onChatMessageCreated` | Firestore: chat message create | Update `lastMessage`/`lastMessageAt` + recipient unread count; FCM push to the recipient |
| `markChatAsRead` | Callable (thread participant) | Reset that side's unread count when the thread is opened |

---

## 8. Security Rules (high level)

- `users/{uid}`: read own; write own profile fields **except** `role` /
  `assignedClubId` (server-only).
- `clubs`, `games`, `tables`, `reservations`, `waitlist`: **read** for any
  authenticated user.
- **Writes** to games/tables/waitlist status: only `request.auth.token.role ==
  'pitboss' && token.assignedClubId == clubId`, or `superadmin`.
- `waitlist` create: a player may create an entry where `userId == auth.uid`;
  a Pit Boss may create walk-ins for their club.
- `reservations` create: player creates own.
- `clubs` CRUD: `superadmin` only.
- `clubOverviews`: read for authenticated users; **no client writes**
  (Cloud-Function-only).
- `chats`: a **player** reads/writes only their own threads (`playerId ==
  auth.uid`); a **Pit Boss** only their club's threads (`clubId ==
  token.assignedClubId`). `messages`: created only by the sender
  (`senderId == auth.uid`), readable by both participants.
- Role checks use the **custom claim** `request.auth.token.role` (no extra read).

---

## 9. Notifications (FCM)

- Tokens stored in `users/{uid}.fcmTokens[]`, refreshed on app start.
- Triggers: seat called, reservation accepted, reservation expiring soon.
- Localized to the user's `lang`.

---

## 10. Internationalization

- `ka` / `en` / `ru` via Flutter `gen-l10n` + ARB files.
- User language stored in profile; affects UI and push copy.

---

## 11. Cost Considerations

- Overview + drill-down keeps Firestore reads well under the free ceiling for a
  pilot.
- Detailed listeners are scoped to the open screen and detached on close.
- Budget alert configured on the Blaze project.
- SMS (phone OTP) is the main variable cost; low at pilot volume.

---

## 12. Architecture & Maintainability (Changeability)

**Guiding principle: changeability above all.** Any change — a colour, a business
rule, a feature toggle, a backend swap, a translation, a string — must touch
**one or two files**, never ripple across the codebase. The structure below
enforces that.

### Layering — Clean Architecture, feature-first

```
lib/
  core/      constants, errors, theme, feature_flags, config, logging,
             migrations, utils
  features/  auth/ clubs/ waitlist/ reservations/ pit_boss_floor/
             super_admin/ profile/ onboarding/
             (each: domain/ data/ presentation/)
  shared/    reusable widgets & services
  l10n/      app_en.arb, app_ka.arb, app_ru.arb
```

Each feature is built in isolation (own domain/data/presentation). A new feature
= a new folder, with no edits to existing ones.

**A. Business rules & constants — never inline.**
`lib/core/constants/business_rules.dart`: `reservationExpiry` (30 min),
`waitlistCallTimeout` (null = manual in MVP; 20 min in v2, gated by
`autoNoShowTimer`), `maxPlayersPerTable` (9), `maxWaitlistsPerPlayer` (null = no
cap MVP), `defaultCurrency` (GEL), `minBuyIn` (>0; no `maxBuyIn` — Tbilisi format is
uncapped), …
`lib/core/constants/validation_rules.dart`: phone format (E.164), name length, …
**Zero magic numbers/strings** elsewhere — all named constants.

**B. Feature flags — `lib/core/feature_flags.dart`.**
MVP default `false`: `multiClubPitBoss`, `autoNoShowTimer`,
`autoReservationConvertToWaitlist`, `deepAnalytics`, `geoMap`, `perSeatIdentity`,
`templateAutoRestore`, `crossClubWaitlist`, `iosSupport`. Environment-based
override (dev/staging/prod). Activating the v2 backlog = flip flags, not rewrite.
*(Light analytics is the un-flagged MVP baseline; `deepAnalytics` gates only the
v2 deep version. `clubChat` defaults **true** — it ships in MVP.)*

**C. Repository pattern — backend behind interfaces.**
Domain defines abstract interfaces returning domain types & `Stream`s
(`AuthRepository`, `UsersRepository`, `ClubsRepository`, `WaitlistRepository`,
`ReservationsRepository`). Data provides concrete `Firebase…Repository`
implementations. **Contract tests** run one suite against any implementation.
⚠️ **Honest boundary:** pure CRUD + reactive reads abstract cleanly, but
Firebase-specific *infrastructure* — real-time listener semantics,
**custom-claims auth**, **Cloud Functions** (aggregation/push/expiry),
**FCM**, **security rules** — does not map 1:1 to another backend and would need
re-implementation. The repository keeps the *app layer* portable; the *infra
layer* is not a free swap. "Swap in a few files" applies to data access, not to
the whole real-time/auth/functions stack.

**D. State management — Riverpod.** Centralised providers per feature; swappable
in tests; compile-time-safe.

**E. Design tokens & theming — `lib/core/theme/`.**
`tokens.dart` (colours, typography, spacing/8pt, radii, shadows, motion, glass
materials — human-readable names like `colorAccentPrimary`, not `c1`);
`components/` (`PsCard`, `StatusBadge`, `StakePill`, `LiveIndicator`,
`FilterPill`, `GlassNavBar`, buttons, inputs). One token file re-skins the whole
app; switching direction (Liquid Sport → Dark Casino → Editorial) is one token
block, not a refactor. Prototyped first in CSS
(`mockups/v3-design-system/`), then ported 1:1 to Dart.

**F. Internationalisation — `lib/l10n/`.** ARB files + `flutter gen-l10n`. **No
hardcoded strings in UI** — every string is an l10n key. Translators edit ARB;
developers don't touch copy.

**G. Environment config — `lib/core/config/environment.dart`.** dev / staging /
prod; separate Firebase project IDs; per-env flag overrides; loaded via
`--dart-define-from-file` (`env-dev.json`, `env-prod.json`).

**H. Data-model versioning — `lib/core/migrations/`.** Every document carries
`schemaVersion`. A field change = one migration file + a bump, not a rewrite;
supports phased Cloud-Function rollout.

**I. Error handling — `lib/core/errors/app_errors.dart`.** Typed error hierarchy;
centralised reporting (Crashlytics-ready); user-facing messages via l10n.

**J. Logging & observability — `lib/core/logging/app_logger.dart`.** Wrapper over
Firebase Analytics; centralised event tracking (change in one file); levels
debug/info/warning/error.

### Contradiction check vs. earlier decisions

- ✅ **Consistent:** no-cap waitlists, manual no-show MVP (now a constant +
  `autoNoShowTimer` flag), light analytics stays MVP (`deepAnalytics` off),
  Android-first (`iosSupport` off), 30-min reservation expiry (now a constant).
- ⚠️ **Tension flagged (C):** "swap backend in a few files" holds for *data
  access only*. The real-time + custom-claims + Cloud-Functions + FCM +
  security-rules design is **Firebase-specific** and would need re-implementation
  elsewhere. Architecture isolates it in the data/infra layer so the rest of the
  app is unaffected — but it is not a trivial swap. No MVP-scope change; just an
  honest boundary.
- ➕ **New (no conflict):** Riverpod, Clean Architecture feature-first, repository
  pattern, `schemaVersion` on documents.

---

## 13. Testing Strategy

- **Pure-Dart unit tests** for domain logic: waitlist ordering & top-insert, seat
  counting / open-seat computation, multi-waitlist resolution on seat, reservation
  expiry rules.
- **Cloud Functions** tested against the Firebase **Local Emulator Suite**.
- **Security rules** tested with the rules emulator (allow/deny per role).
- **Widget tests** for key screens (club list, club detail, Live Floor, waitlist).
- Local dev on Windows uses Android emulator + Firebase emulators (no Mac needed).

---

## 14. v2 Backlog (deferred)

iOS build/release · per-seat player identity & chip stacks · auto no-show timer
on waitlist calls · multi-day / future reservations · geo / map / distance sorting
· previous-session table template auto-restore · multi-club Pit Boss · deep
analytics & rake/revenue tracking · player profiles / loyalty · cross-club
waitlist resolution. *(Private club chat moved into MVP — see §6/§7/§9.)*

---

## 15. Assumptions

- Reservation 30-min window counts from `reservedTime` (grace), confirmed.
- One Pit Boss = one club in MVP.
- Club list sort: live status (🟢 Live → 🟡 Open but empty → ⚫ Closed), then
  city/name. Live status is computed client-side from `status` + `openingHours`
  + current time + open games. Geo/distance sorting is v2.
- Currency displayed as GEL.
- No hard cap on simultaneous waitlists per player in MVP (revisit if abused).
- A single production Firebase project; local dev via emulators (separate
  staging project is v2).

---

## 16. Build & Release

- Flutter (Dart), single app, role-based routing.
- **Android-first**: build/sign/distribute from Windows.
- iOS: deferred (v2) via Codemagic / GitHub Actions macOS runners or a Mac.
- Firebase: one prod project; Local Emulator Suite for development.

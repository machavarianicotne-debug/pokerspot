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

See §13 (v2 backlog). Notably: no iOS at launch, no per-seat player identity,
no deep analytics, no in-app chat, no multi-day reservations.

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
  type(NLH|PLO)  blinds(string e.g. "1/3")  buyInMin  buyInMax
  status(running|closed)  createdAt

clubs/{clubId}/games/{gameId}/tables/{tableId}
  name  maxSeats(default 9)  seatedCount  status(open|closed|breaking)  openedAt

clubs/{clubId}/waitlist/{entryId}
  gameId  userId  displayName  position(float, for ordering & top-insert)
  status(waiting|called|seated|no_show|cancelled)  source(app|manual|reservation)
  joinedAt  calledAt  seatedAt

clubs/{clubId}/reservations/{resId}
  gameId  userId  displayName  partySize  reservedTime(timestamp, same-day)
  note  status(pending|accepted|rejected|arrived|expired|cancelled)
  createdAt  acceptedAt  expiresAt

clubOverviews/{clubId}                # denormalized, Cloud-Function-maintained
  clubName  city  status  openingHours  photoUrl
  games: [ { gameId, type, blinds, openTables, openSeats, waitlistCount } ]
  updatedAt
  # client derives live status (🟢/🟡/⚫) from status + openingHours + games
```

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
   **tap-to-call phone**, opening hours), then per-stake live cards below.
   Tap-to-call opens the device dialer via Flutter `url_launcher` (small, MVP).
4. **Join waitlist** for a stake (multiple allowed); see own position; leave.
5. **Reserve** — same-day, choose stake + time + party size + note.
6. **My status** — own active waitlists & reservations.
7. **Profile** — edit displayName & language; **Logout**; **Delete Account**
   (see "Account deletion & logout" below).
8. **Push** — seat called, reservation accepted, reservation expiring.

### Pit Boss — "Live Floor" (own club)

- **Games overview** cards: stake, open tables, open seats, waitlist count;
  `+ New Game` (choose NLH/PLO + blinds + buy-in → opens an empty table).
- **Game detail:**
  - **Tables:** visual seat grid per table; `(- / +)` or tap-to-toggle seats;
    `+ Add Table` (another table at the same stake); open / close / break a table.
    - Tap **empty** seat → occupied → prompt: **Call waitlist #1** or **manual
      seat** (walk-in not on the list).
    - Tap **occupied** seat → empty → prompt: **manual** (player left) or advance
      to **next called** → notification.
  - **Waitlist** (ordered): per entry `[Call] [Seat] [No-show] [Remove]`; called
    entries highlighted; `+ Add walk-in`.
  - **Reservations** (pending): `[Accept] [Reject]`; accepted show `[Arrived]`.
- An evening starts with an **empty** club (no auto-restore of a previous
  template in MVP).

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

## 12. Testing Strategy

- **Pure-Dart unit tests** for domain logic: waitlist ordering & top-insert, seat
  counting / open-seat computation, multi-waitlist resolution on seat, reservation
  expiry rules.
- **Cloud Functions** tested against the Firebase **Local Emulator Suite**.
- **Security rules** tested with the rules emulator (allow/deny per role).
- **Widget tests** for key screens (club list, club detail, Live Floor, waitlist).
- Local dev on Windows uses Android emulator + Firebase emulators (no Mac needed).

---

## 13. v2 Backlog (deferred)

iOS build/release · per-seat player identity & chip stacks · auto no-show timer
on waitlist calls · multi-day / future reservations · geo / map / distance sorting
· previous-session table template auto-restore · multi-club Pit Boss · deep
analytics & rake/revenue tracking · in-app chat / player profiles / loyalty ·
cross-club waitlist resolution.

---

## 14. Assumptions

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

## 15. Build & Release

- Flutter (Dart), single app, role-based routing.
- **Android-first**: build/sign/distribute from Windows.
- iOS: deferred (v2) via Codemagic / GitHub Actions macOS runners or a Mac.
- Firebase: one prod project; Local Emulator Suite for development.

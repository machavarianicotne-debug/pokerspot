# Waitlist + Sessions Implementation Plan (Plan 4)

> Concise task list (scope + acceptance). Builds on Plans 1–3. The waitlist is the core live feature: a Player joins a club's **per-stake** waitlist; the Pit Boss sees the live list, calls a player, and seats them at a table+seat (creating a live Session with a timer). **Approved.**

**Goal:** Player joins a club's waitlist for a stake (game variant + blinds + currency) and sees their status (waiting / called, with cancel). Pit Boss sees their club's live waitlist, calls a player, and seats them at a table+seat → a live Session with an elapsed timer (+ End).

**Architecture:** Feature-first (`features/floor/` for tables/waitlist/sessions, or split into `features/{tables,waitlist,sessions}/`). Repository pattern + Riverpod StreamProviders over **Firestore snapshots end-to-end** (no intermediate cache), Fakes for tests — same pattern as clubs (Plan 3).

**Tech Stack:** existing (`cloud_firestore`, `flutter_riverpod`, `go_router`). No new packages expected.

> **Reservations were deferred entirely** from this plan (own mini-plan later). Plan 4 = waitlist + sessions only.

---

## Data model (approved)
- `clubs/{clubId}/tables/{tableId}` (subcollection): `number:int`, `variant:string` (NLH|PLO|PLO5|PLO6), `smallBlind:num`, `bigBlind:num`, `currency:string` (GEL|USD|EUR), `seatCount:int`, `open:bool`.
- `waitlist/{entryId}` (top-level): `clubId`, `playerUid`, `playerName`, stake fields (`variant`, `smallBlind`, `bigBlind`, `currency`), `status` (waiting|called|seated|cancelled), `createdAt`, `calledAt?`. **Per-stake** — no `tableId` at entry creation.
- `sessions/{sessionId}` (top-level): `clubId`, `tableId`, `seatNumber:int`, `playerUid`, `playerName`, stake fields, `startedAt`, `endedAt?`, `status` (active|ended). `tableId`/`seatNumber` assigned at seat time.

Two top-level collections (waitlist, sessions) + tables nested under their club. Pit Boss queries `where clubId==X`; Player queries `where playerUid==me` — single-field, no collection-group indexes.

**Pit Boss → club binding:** `AppUser` gains a nullable `clubId` (Q1 option a). The Pit Boss's waitlist screen uses `currentUser.clubId`. Set manually in the Firestore Console for now (Super Admin staff management is a later plan).

---

## Task list (9)

### Task 1: Domain models + AppUser.clubId
- `GameVariant` (reuse Plan 1 constant if present), `Stakes` value object (variant+sb+bb+currency + `label`), `PokerTable`, `WaitlistEntry` + `WaitlistStatus`, `Session`. Pure Dart; `==`/`hashCode`/`copyWith`/`fromMap`/`toMap`. No Firebase imports.
- **AppUser.clubId** (nullable String): unlock AppUser for this addition only; `fromMap` defaults missing → null (legacy users); update `==`/`hashCode`/`copyWith`/`toMap`. Add a Plan 2 doc refinement banner (like firstName/lastName).
- **Accept:** analyze clean; model + AppUser tests green.

### Task 2: Repository interfaces + Fakes + Firebase impls
- `TablesRepository` (`watchTables(clubId)`), `WaitlistRepository` (`watchByClub`, `watchByPlayer`, `join`, `cancel`, `call`, `seat`), `SessionsRepository` (`watchActiveByClub`, `watchByPlayer`, `end`). Fakes (in-memory, replay-on-subscribe like FakeClubsRepository) + Firebase (DI `FirebaseFirestore`). `seat` transactionally creates a Session + flips the entry to seated. Fakes unit-tested; Firebase not.
- **Accept:** analyze clean; fake repo tests green.

### Task 3: Riverpod providers
- Repo providers (Firebase-backed) + stream providers: `tablesProvider(clubId)`, `clubWaitlistProvider(clubId)`, `myWaitlistProvider` (uid from auth), `clubSessionsProvider(clubId)`. Provider tests with fakes.
- **Accept:** analyze clean; provider tests green.

### Task 4: Player — join waitlist (unlock ClubDetailsScreen)
- Club details gains a "Join waitlist" button → a sheet listing the club's distinct stakes (from its `tables`); pick one → `WaitlistRepository.join(...)` with the signed-in player's uid + display name. If already waiting for that stake, show that state instead.
- **Accept:** widget tests (join creates entry; already-waiting state); analyze clean.

### Task 5: Player — my waitlist status widget
- A section/banner (on club details and/or PlayerHome) showing the player's active waitlist entries: stake + status (waiting / "You've been called") + a Cancel action.
- **Accept:** widget tests (waiting + called render; cancel removes); analyze clean.

### Task 6: Pit Boss — live club waitlist + Call (unlock PitBossHome)
- PitBossHome → live waitlist for `currentUser.clubId` (ordered by createdAt), each row: player name + stake label + waiting time; **Call** action (waiting→called, sets calledAt). If `clubId == null`, show a "no club assigned" message.
- **Accept:** widget tests (list renders; call transitions status; null-club message); analyze clean.

### Task 7: Pit Boss — seat → Session + live timers + End
- From a called entry: **Seat** → pick a table + seat number → `WaitlistRepository.seat(...)` creates a `Session` (active, startedAt) and flips the entry to seated. Sessions list per club with a live-updating elapsed timer; **End** session.
- **Accept:** widget tests (seat creates session; timer renders; end); analyze clean.

### Task 8: l10n keys — **front-loaded before Tasks 4–7** (their UI consumes these keys)
- Add waitlist/session keys (en/ka/ru): join, stake picker, statuses, call, seat, end, "you've been called", "no club assigned", etc. `flutter gen-l10n`.
- **Accept:** analyze clean; tests green.
- **Note:** committed before Task 4 because Tasks 4–7 reference these getters (otherwise their gate fails to compile) — same as Plan 3.

### Task 9: Router/home wiring + seed tables + README + deploy
- Routes for my-waitlist / pit-boss floor as needed; wire PlayerHome/PitBossHome.
- `tools/seed_tables.dart` (mirror `seed_clubs.dart`): seed a few demo tables per demo club (fixed ids, idempotent); seed + read-back verify UI.
- README: tables/waitlist/sessions schema + how to run the table seeder + how to set a Pit Boss's `clubId`. Build web + `firebase deploy`; confirm HTTP 200.
- **Accept:** full suite green; analyze clean; live HTTP 200.

---

## Deferred to later plans
- **Reservations** (reserve a stake with a 30-min arrival deadline) → own mini-plan later.
- **Pit Boss "call next" notification / push** to the called player → Plan 5.
- **Rich Pit Boss visual UI** (seat map, editable blinds, walk-in non-registered players, drag-to-seat) + **Pit Boss table management** → Plan 5.
- **Automated expiry** of `callDeadline` (Cloud Functions) → Plan 5/7 (Blaze). Plan 4 may store a deadline but enforcement is visual/manual.
- **Security rules** → Plan 7.
- **Multi-currency conversion** — store `currency` only; no FX.

## Locked files this plan unlocks (Plans 1–3)
- `lib/features/auth/domain/app_user.dart` — add nullable `clubId` ONLY (Task 1).
- `lib/features/clubs/presentation/club_details_screen.dart` — Join-waitlist UI (Task 4).
- `lib/features/home/presentation/player_home.dart` — my-waitlist banner (Task 5); `pit_boss_home.dart` — live waitlist + seat (Tasks 6–7).
- `lib/app/router.dart` — new routes (Task 9).
- `tools/` — new `seed_tables.dart` (Task 9).

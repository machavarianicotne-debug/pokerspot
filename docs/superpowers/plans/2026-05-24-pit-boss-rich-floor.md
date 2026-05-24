# Plan 5 — Pit Boss Rich Floor

> Autonomous execution (Plans 5-6-7 run). Simplest correct implementation that
> passes gates; polish is a follow-up. Liquid Sport only, reuse `Ps*` widgets.

**Goal:** Give the Pit Boss real table management — create/edit/delete tables, a
visual seat map per table, and walk-in seating — replacing the number + seat
dropdown of Plan 4.

**Architecture:** Extend `TablesRepository` (CRUD) and `SessionsRepository`
(`seatWalkIn`) — domain interface + Fake + Firebase. New presentation under
`features/floor/presentation/` wired into the Pit Boss **Tables** tab (was a
stub). Seats occupancy is derived from active sessions (`clubSessionsProvider`),
not stored on the table.

## Data model (no new collections)
- `clubs/{clubId}/tables/{id}` — unchanged fields (`number`, `variant`,
  `smallBlind`, `bigBlind`, `currency`, `seatCount`, `open`). CRUD added.
- `sessions/{id}` — walk-ins reuse the existing shape with
  `playerUid = 'walk-in:<rand>'`, `playerName` PB-supplied (default "Walk-in").

## Tasks
1. **doc** — this file (first commit).
2. **Repo CRUD** — `TablesRepository.createTable/updateTable/deleteTable` +
   `SessionsRepository.seatWalkIn`; Fake + Firebase impls; Fake unit tests.
3. **Providers** — `seatedSessionsByTableProvider`-style helpers if needed
   (reuse `clubSessionsProvider`; compute occupied seats in the UI).
4. **Tables tab** — `TablesScreen`: list the club's tables as `PsCard`s with
   occupancy `X/seatCount`, tap → table detail; "New table" action.
5. **Table editor** — `PsSheet` form (variant pills, blinds, currency, seat
   count, open toggle) for create + edit; delete with confirm.
6. **Seat map** — `TableDetailScreen`: seats as a wrap of seat circles (filled +
   initials when occupied, glass + tappable when free). Tapping a free seat →
   seat a called/waiting player or a walk-in. End session from an occupied seat.
7. **l10n** — table/seat/walk-in keys in en/ka/ru; `flutter gen-l10n`.
8. **Cleanup** — delete `tools/seed_tables.dart` + `tools/seed_tables.bat`.

## Deferred (per autonomy order — heavy/risky)
Drag-to-seat gesture, end-of-shift summary, search/filter, sounds, precise oval
seat geometry (a wrapped seat-circle layout ships instead).

## Gate
`flutter analyze` clean + `flutter test` green per commit; single
`firebase deploy` at plan end.

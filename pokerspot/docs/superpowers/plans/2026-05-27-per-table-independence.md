# Per-Table Independence Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make every physical poker table fully independent — its own waitlist, its own open-seat count, and its own reservations — even when two tables share identical stakes (e.g. two NLH 5/10).

**Architecture:** Today everything is keyed by *stake label* (`stakeKey = variant-sb-bb-currency`). Two same-stake tables therefore share one waitlist, one reservation queue, and one scoreboard entry. The fix is to carry a `tableId` on `WaitlistEntry`, `Reservation`, and the denormalized `ClubGame`, then filter/aggregate by `tableId` instead of stake label across the Cloud Function, the player screens (club details, reservation flow), and the Pit screens (tables list, game detail). `Session` already has `tableId`, so seating is already per-table; this plan brings waitlist + reservations + scoreboard to the same model.

**Tech Stack:** Flutter + Riverpod (StreamProvider/Provider), Firebase Firestore, Cloud Functions (Node.js, `functions/index.js`), pure-Dart domain models with fake + firebase repository pairs, `flutter_test` widget/unit tests.

**Backward-compatibility note:** `tableId` is added as nullable on the entry/reservation models, so existing Firestore docs (written before this change) simply read `tableId == null` and drop out of the new per-table views. Waitlist entries and reservations are short-lived (they expire or get seated), so this self-heals quickly. Before testing on the deployed app, clear any stale `waitlist`/`reservations` docs in the Firebase console, or just let them cycle out.

---

## File Structure

| File | Responsibility | Change |
|------|----------------|--------|
| `lib/features/floor/domain/waitlist_entry.dart` | Waitlist entry model | + `String? tableId` |
| `lib/features/floor/domain/reservation.dart` | Reservation model | + `String? tableId` |
| `lib/features/clubs/domain/club.dart` | `ClubGame` denormalized scoreboard | + `String tableId`; now one entry per open table |
| `lib/features/floor/domain/floor_repositories.dart` | Repo interfaces | `join` + `reserve` gain `String? tableId` |
| `lib/features/floor/data/firebase_floor_repositories.dart` | Firestore repos | write `tableId` |
| `lib/features/floor/data/fake_floor_repositories.dart` | In-memory repos | store `tableId` |
| `functions/index.js` | `recomputeClub`, `onReservationCreate`, `notifySeatOpen` | per-table aggregation + seating + notify |
| `lib/features/clubs/presentation/club_details_screen.dart` | Player: one card per table | lookups by `tableId` |
| `lib/features/floor/presentation/reservation_flow_screen.dart` | Player: reserve a seat | pick a **table**, pass `tableId` |
| `lib/features/floor/presentation/game_detail_screen.dart` | Pit: game detail | keyed by `tableId`, single table + its own lists |
| `lib/features/floor/presentation/tables_screen.dart` | Pit: tables list | navigate + count by `tableId` |
| Tests (see each task) | — | updated/added |

---

## Task 1: Add `tableId` to WaitlistEntry

**Files:**
- Modify: `lib/features/floor/domain/waitlist_entry.dart`
- Test: `test/features/floor/poker_table_test.dart` (append) — or create `test/features/floor/waitlist_entry_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/floor/waitlist_entry_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/features/floor/domain/stakes.dart';
import 'package:pokerspot/features/floor/domain/waitlist_entry.dart';

void main() {
  const stakes = Stakes(variant: GameVariant.nlh, smallBlind: 5, bigBlind: 10, currency: 'GEL');

  test('WaitlistEntry round-trips tableId through toMap/fromMap', () {
    final e = WaitlistEntry(
      id: 'e1', clubId: 'vake', tableId: 't1', playerUid: 'u', playerName: 'Nino',
      stakes: stakes, status: WaitlistStatus.waiting, createdAt: null, calledAt: null);
    final round = WaitlistEntry.fromMap('e1', e.toMap());
    expect(round.tableId, 't1');
    expect(round, e);
  });

  test('WaitlistEntry tableId is null for legacy docs (no tableId key)', () {
    final e = WaitlistEntry.fromMap('e1', {
      'clubId': 'vake', 'playerUid': 'u', 'playerName': 'Nino',
      ...stakes.toMap(), 'status': 'waiting',
    });
    expect(e.tableId, isNull);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/floor/waitlist_entry_test.dart`
Expected: FAIL — `No named parameter with the name 'tableId'`.

- [ ] **Step 3: Add the field**

In `lib/features/floor/domain/waitlist_entry.dart`, add `tableId` (nullable) immediately after `clubId` everywhere:

Field block (after `final String clubId;`):
```dart
  final String clubId;
  final String? tableId;
```

Constructor (after `required this.clubId,`):
```dart
    required this.clubId,
    this.tableId,
```

`fromMap` (after `clubId: ...`):
```dart
        clubId: (m['clubId'] ?? '') as String,
        tableId: m['tableId'] as String?,
```

`toMap` (after `'clubId': clubId,`):
```dart
        'clubId': clubId,
        'tableId': tableId,
```

`copyWith` — add param + body:
```dart
  WaitlistEntry copyWith({
    String? id,
    String? clubId,
    String? tableId,
    String? playerUid,
```
```dart
        id: id ?? this.id,
        clubId: clubId ?? this.clubId,
        tableId: tableId ?? this.tableId,
        playerUid: playerUid ?? this.playerUid,
```

`==` (after `clubId == other.clubId &&`):
```dart
          clubId == other.clubId &&
          tableId == other.tableId &&
```

`hashCode` — add `tableId`:
```dart
  int get hashCode => Object.hash(
      id, clubId, tableId, playerUid, playerName, stakes, status, createdAt, calledAt);
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/floor/waitlist_entry_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/floor/domain/waitlist_entry.dart test/features/floor/waitlist_entry_test.dart
git commit -m "feat(floor): add tableId to WaitlistEntry"
```

---

## Task 2: Add `tableId` to Reservation

**Files:**
- Modify: `lib/features/floor/domain/reservation.dart`
- Test: create `test/features/floor/reservation_model_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/features/floor/domain/stakes.dart';
import 'package:pokerspot/features/floor/domain/reservation.dart';

void main() {
  const stakes = Stakes(variant: GameVariant.nlh, smallBlind: 5, bigBlind: 10, currency: 'GEL');

  test('Reservation round-trips tableId', () {
    final r = Reservation(
      id: 'r1', clubId: 'vake', tableId: 't2', playerUid: 'u', playerName: 'Levan',
      stakes: stakes, status: ReservationStatus.held, heldUntil: null, createdAt: null);
    final round = Reservation.fromMap('r1', r.toMap());
    expect(round.tableId, 't2');
    expect(round, r);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/floor/reservation_model_test.dart`
Expected: FAIL — `No named parameter with the name 'tableId'`.

- [ ] **Step 3: Add the field**

In `lib/features/floor/domain/reservation.dart`:

Field (after `final String clubId;`):
```dart
  final String clubId;
  final String? tableId;
```

Constructor (after `required this.clubId,`):
```dart
    required this.clubId,
    this.tableId,
```

`fromMap` (after `clubId: ...`):
```dart
        clubId: (m['clubId'] ?? '') as String,
        tableId: m['tableId'] as String?,
```

`toMap` (after `'clubId': clubId,`):
```dart
        'clubId': clubId,
        'tableId': tableId,
```

`copyWith` — this model's `copyWith` only takes `status`/`heldUntil`; preserve `tableId` by adding it to the constructed object:
```dart
  Reservation copyWith({ReservationStatus? status, DateTime? heldUntil}) => Reservation(
        id: id,
        clubId: clubId,
        tableId: tableId,
        playerUid: playerUid,
```

`==` (after `clubId == other.clubId &&`):
```dart
          clubId == other.clubId &&
          tableId == other.tableId &&
```

`hashCode`:
```dart
  int get hashCode =>
      Object.hash(id, clubId, tableId, playerUid, playerName, stakes, status, heldUntil, createdAt);
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/floor/reservation_model_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/floor/domain/reservation.dart test/features/floor/reservation_model_test.dart
git commit -m "feat(floor): add tableId to Reservation"
```

---

## Task 3: Make `ClubGame` per-table (add `tableId`)

`ClubGame` is the denormalized per-stake scoreboard on the club doc. It becomes per-OPEN-TABLE. Add `tableId`; keep the `tables` field (it will always be `1` per entry, so `clubs_list_screen`'s `fold((a,g)=>a+g.tables)` still yields the total open-table count).

**Files:**
- Modify: `lib/features/clubs/domain/club.dart`
- Test: create `test/features/clubs/club_game_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/features/clubs/domain/club.dart';

void main() {
  test('ClubGame round-trips tableId', () {
    final g = ClubGame.fromMap(const {
      'label': 'NLH 5/10 GEL', 'type': 'NLH', 'tableId': 't1',
      'minBuyIn': 500, 'avgStack': 25000, 'tables': 1, 'openSeats': 3, 'waiting': 2,
    });
    expect(g.tableId, 't1');
    expect(g.openSeats, 3);
    expect(g.waiting, 2);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/clubs/club_game_test.dart`
Expected: FAIL — `The getter 'tableId' isn't defined for the type 'ClubGame'`.

- [ ] **Step 3: Add the field**

In `lib/features/clubs/domain/club.dart`, `ClubGame`:

Field (after `final String label;`):
```dart
  final String label; // e.g. "NLH 5/10 GEL"
  final String tableId; // the physical table this scoreboard entry belongs to
```

Constructor — add with a default so existing call sites stay valid (after `required this.label,` is not used; the ctor uses `required` for others — add `this.tableId = ''`):
```dart
  const ClubGame({
    required this.label,
    this.tableId = '',
    required this.type,
```

`fromMap` (after `label: ...`):
```dart
        label: (m['label'] ?? '') as String,
        tableId: (m['tableId'] ?? '') as String,
```

`==` (after `label == other.label &&`):
```dart
          label == other.label &&
          tableId == other.tableId &&
```

`hashCode`:
```dart
  int get hashCode => Object.hash(label, tableId, type, minBuyIn, avgStack, tables, openSeats, waiting);
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/clubs/club_game_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/clubs/domain/club.dart test/features/clubs/club_game_test.dart
git commit -m "feat(clubs): add tableId to ClubGame (per-table scoreboard)"
```

---

## Task 4: `WaitlistRepository.join` carries `tableId`

**Files:**
- Modify: `lib/features/floor/domain/floor_repositories.dart:40-45`
- Modify: `lib/features/floor/data/firebase_floor_repositories.dart:91-107`
- Modify: `lib/features/floor/data/fake_floor_repositories.dart:127-146`
- Test: `test/features/floor/fake_floor_repositories_test.dart` (append)

- [ ] **Step 1: Write the failing test**

Append to `test/features/floor/fake_floor_repositories_test.dart` (inside `main()`):

```dart
  test('FakeWaitlistRepository.join stores the tableId', () async {
    final store = FakeFloorStore();
    final repo = FakeWaitlistRepository(store);
    await repo.join(
      clubId: 'vake', tableId: 't1', playerUid: 'u', playerName: 'Nino',
      stakes: const Stakes(variant: GameVariant.nlh, smallBlind: 5, bigBlind: 10, currency: 'GEL'));
    final entry = store.waitlist.values.single;
    expect(entry.tableId, 't1');
  });
```

(Ensure the file imports `Stakes`/`GameVariant` from `package:pokerspot/features/floor/domain/stakes.dart` and `FakeFloorStore`/`FakeWaitlistRepository` — they are already imported in this test file.)

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/floor/fake_floor_repositories_test.dart`
Expected: FAIL — `No named parameter with the name 'tableId'`.

- [ ] **Step 3: Add `tableId` to the interface**

`lib/features/floor/domain/floor_repositories.dart`, `WaitlistRepository.join`:
```dart
  /// Player joins a specific table's waitlist.
  Future<void> join({
    required String clubId,
    String? tableId,
    required String playerUid,
    required String playerName,
    required Stakes stakes,
  });
```

- [ ] **Step 4: Write `tableId` in the Firebase repo**

`lib/features/floor/data/firebase_floor_repositories.dart`, `FirebaseWaitlistRepository.join`:
```dart
  @override
  Future<void> join({
    required String clubId,
    String? tableId,
    required String playerUid,
    required String playerName,
    required Stakes stakes,
  }) {
    return _col.add({
      'clubId': clubId,
      'tableId': tableId,
      'playerUid': playerUid,
      'playerName': playerName,
      ...stakes.toMap(),
      'status': WaitlistStatus.waiting.asString,
      'createdAt': FieldValue.serverTimestamp(),
      'calledAt': null,
    });
  }
```

- [ ] **Step 5: Store `tableId` in the fake repo**

`lib/features/floor/data/fake_floor_repositories.dart`, `FakeWaitlistRepository.join`:
```dart
  @override
  Future<void> join({
    required String clubId,
    String? tableId,
    required String playerUid,
    required String playerName,
    required Stakes stakes,
  }) async {
    final id = store.nextId('wl');
    store.waitlist[id] = WaitlistEntry(
      id: id,
      clubId: clubId,
      tableId: tableId,
      playerUid: playerUid,
      playerName: playerName,
      stakes: stakes,
      status: WaitlistStatus.waiting,
      createdAt: DateTime.now(),
      calledAt: null,
    );
    store.notify();
  }
```

- [ ] **Step 6: Run test to verify it passes**

Run: `flutter test test/features/floor/fake_floor_repositories_test.dart`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/features/floor/domain/floor_repositories.dart lib/features/floor/data/firebase_floor_repositories.dart lib/features/floor/data/fake_floor_repositories.dart test/features/floor/fake_floor_repositories_test.dart
git commit -m "feat(floor): WaitlistRepository.join carries tableId"
```

---

## Task 5: `ReservationsRepository.reserve` carries `tableId`

**Files:**
- Modify: `lib/features/floor/domain/floor_repositories.dart:131-137`
- Modify: `lib/features/floor/data/firebase_floor_repositories.dart:305-323`
- Modify: `lib/features/floor/data/fake_floor_repositories.dart:218-238`
- Test: `test/features/floor/fake_floor_repositories_test.dart` (append)

- [ ] **Step 1: Write the failing test**

Append to `test/features/floor/fake_floor_repositories_test.dart`:

```dart
  test('FakeReservationsRepository.reserve stores the tableId', () async {
    final store = FakeFloorStore();
    final repo = FakeReservationsRepository(store);
    await repo.reserve(
      clubId: 'vake', tableId: 't2', playerUid: 'u', playerName: 'Levan',
      stakes: const Stakes(variant: GameVariant.nlh, smallBlind: 5, bigBlind: 10, currency: 'GEL'),
      durationMinutes: 30);
    expect(store.reservations.values.single.tableId, 't2');
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/floor/fake_floor_repositories_test.dart`
Expected: FAIL — `No named parameter with the name 'tableId'`.

- [ ] **Step 3: Interface**

`lib/features/floor/domain/floor_repositories.dart`, `ReservationsRepository.reserve`:
```dart
  /// Player reserves a seat at a specific table — instant hold for [durationMinutes].
  Future<void> reserve({
    required String clubId,
    String? tableId,
    required String playerUid,
    required String playerName,
    required Stakes stakes,
    required int durationMinutes,
  });
```

- [ ] **Step 4: Firebase repo**

`lib/features/floor/data/firebase_floor_repositories.dart`, `FirebaseReservationsRepository.reserve`:
```dart
  @override
  Future<void> reserve({
    required String clubId,
    String? tableId,
    required String playerUid,
    required String playerName,
    required Stakes stakes,
    required int durationMinutes,
  }) {
    return _col.add({
      'clubId': clubId,
      'tableId': tableId,
      'playerUid': playerUid,
      'playerName': playerName,
      ...stakes.toMap(),
      'status': ReservationStatus.held.asString,
      'heldUntil': Timestamp.fromDate(DateTime.now().add(Duration(minutes: durationMinutes))),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
```

- [ ] **Step 5: Fake repo**

`lib/features/floor/data/fake_floor_repositories.dart`, `FakeReservationsRepository.reserve`:
```dart
  @override
  Future<void> reserve({
    required String clubId,
    String? tableId,
    required String playerUid,
    required String playerName,
    required Stakes stakes,
    required int durationMinutes,
  }) async {
    final id = store.nextId('res');
    store.reservations[id] = Reservation(
      id: id,
      clubId: clubId,
      tableId: tableId,
      playerUid: playerUid,
      playerName: playerName,
      stakes: stakes,
      status: ReservationStatus.held,
      heldUntil: DateTime.now().add(Duration(minutes: durationMinutes)),
      createdAt: DateTime.now(),
    );
    store.notify();
  }
```

- [ ] **Step 6: Run test to verify it passes**

Run: `flutter test test/features/floor/fake_floor_repositories_test.dart`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/features/floor/domain/floor_repositories.dart lib/features/floor/data/firebase_floor_repositories.dart lib/features/floor/data/fake_floor_repositories.dart test/features/floor/fake_floor_repositories_test.dart
git commit -m "feat(floor): ReservationsRepository.reserve carries tableId"
```

---

## Task 6: `recomputeClub` emits one game per open table

The Cloud Function currently groups open tables by `stakeKey` and aggregates. Switch to one `ClubGame` per OPEN TABLE, keyed by `tableId`, with that table's own `openSeats` and `waiting`. Keep club-level totals; compute `stakes` (distinct stake count) separately so the club list's "N stakes" stays correct.

**Files:**
- Modify: `functions/index.js:135-196` (the `recomputeClub` function)

- [ ] **Step 1: Replace the `recomputeClub` body**

Replace the whole function (currently `async function recomputeClub(clubId) { ... }`, lines ~135-196) with:

```javascript
async function recomputeClub(clubId) {
  if (!clubId) return;
  const [tablesSnap, sessionsSnap, waitlistSnap] = await Promise.all([
    db.collection('clubs').doc(clubId).collection('tables').get(),
    db.collection('sessions').where('clubId', '==', clubId).where('status', '==', 'active').get(),
    db.collection('waitlist').where('clubId', '==', clubId).get(),
  ]);

  // One scoreboard entry PER OPEN TABLE (tables are independent, even at the
  // same stake). Keyed by tableId so the player's per-table card lines up.
  const games = {}; // tableId -> game accumulator
  const stakeSet = new Set(); // distinct stakes running (for club.stakes)
  tablesSnap.forEach((d) => {
    const t = d.data();
    if (t.open === false) return;
    stakeSet.add(stakeKey(t));
    games[d.id] = {
      tableId: d.id,
      label: stakeLabel(t),
      type: (t.variant || '').toUpperCase(),
      minBuyIn: t.minBuyIn != null ? t.minBuyIn : null,
      avgStack: t.avgStack != null ? t.avgStack : null,
      tables: 1,
      seats: t.seatCount || 0,
      occupied: 0,
      waiting: 0,
    };
  });
  sessionsSnap.forEach((d) => {
    const g = games[d.data().tableId];
    if (g) g.occupied += 1;
  });
  waitlistSnap.forEach((d) => {
    const w = d.data();
    if (w.status !== 'waiting' && w.status !== 'called') return;
    const g = games[w.tableId];
    if (g) g.waiting += 1;
  });

  const gamesArr = Object.values(games)
    .sort((a, b) => a.tableId.localeCompare(b.tableId))
    .map((g) => ({
      label: g.label, tableId: g.tableId, type: g.type, minBuyIn: g.minBuyIn, avgStack: g.avgStack,
      tables: g.tables, openSeats: Math.max(0, g.seats - g.occupied), waiting: g.waiting,
    }));
  const totalOccupied = Object.values(games).reduce((a, g) => a + g.occupied, 0);

  await db.collection('clubs').doc(clubId).set(
    {
      live: gamesArr.length > 0,
      openSeats: gamesArr.reduce((a, g) => a + g.openSeats, 0),
      players: totalOccupied,
      stakes: stakeSet.size,
      waiting: gamesArr.reduce((a, g) => a + g.waiting, 0),
      games: gamesArr,
    },
    { merge: true },
  );
}
```

(Note: `live` now reflects "has an open table" — matching the existing `clubs_list_screen` rule `live = club.games.isNotEmpty`, and the recent commit "a club with open tables is LIVE even with 0 seated players".)

- [ ] **Step 2: Syntax-check**

Run: `node --check functions/index.js`
Expected: no output, exit 0 (syntax OK).

- [ ] **Step 3: Commit**

```bash
git add functions/index.js
git commit -m "feat(functions): recomputeClub emits one game per open table"
```

---

## Task 7: Per-table reservation seating + seat-open notify

**Files:**
- Modify: `functions/index.js` — `onReservationCreate` (~259-293) and `notifySeatOpen` (~312-330)

- [ ] **Step 1: `onReservationCreate` — seat at the reserved table only**

Replace the table-selection block. Change the filter from "any open same-stake table" to "the reserved table". Replace:

```javascript
    const key = stakeKey(r);
    const tablesSnap = await db.collection('clubs').doc(r.clubId).collection('tables').get();
    const tables = tablesSnap.docs
      .map((d) => ({ id: d.id, ...d.data() }))
      .filter((t) => t.open !== false && stakeKey(t) === key);
    if (tables.length === 0) return;
```

with:

```javascript
    // The player reserved a SPECIFIC table — only seat them there.
    const tablesSnap = await db.collection('clubs').doc(r.clubId).collection('tables').get();
    const tables = tablesSnap.docs
      .map((d) => ({ id: d.id, ...d.data() }))
      .filter((t) => t.open !== false && (r.tableId == null || t.id === r.tableId));
    if (tables.length === 0) return;
```

(The `r.tableId == null` clause keeps legacy reservations working: if a reservation has no tableId, fall back to the old any-open-table behaviour.)

- [ ] **Step 2: `notifySeatOpen` — notify that table's waiters**

In `notifySeatOpen`, replace the per-stake match:

```javascript
    const key = stakeKey(after);
    const snap = await db.collection('waitlist').where('clubId', '==', after.clubId).get();
    const tokens = [];
    for (const d of snap.docs) {
      const w = d.data();
      if (w.status === 'waiting' && stakeKey(w) === key) {
        tokens.push(...(await playerTokens(w.playerUid)));
      }
    }
```

with:

```javascript
    const snap = await db.collection('waitlist').where('clubId', '==', after.clubId).get();
    const tokens = [];
    for (const d of snap.docs) {
      const w = d.data();
      // Notify players waiting for THIS table (legacy entries with no tableId
      // fall back to a stake match so they still hear about an opening).
      const sameTable = w.tableId != null ? w.tableId === after.tableId : stakeKey(w) === stakeKey(after);
      if (w.status === 'waiting' && sameTable) {
        tokens.push(...(await playerTokens(w.playerUid)));
      }
    }
```

- [ ] **Step 3: Syntax-check**

Run: `node --check functions/index.js`
Expected: exit 0.

- [ ] **Step 4: Commit**

```bash
git add functions/index.js
git commit -m "feat(functions): reservation seats at its table; seat-open notifies that table's waiters"
```

---

## Task 8: Player club-details — per-table lookups

`_TablesAndGames` already renders one `_GameCard` per open table. Switch its data lookups from stake label to `tableId`: the scoreboard entry, the player's own waitlist entry, the seated guard, and the join call.

**Files:**
- Modify: `lib/features/clubs/presentation/club_details_screen.dart` (`_TablesAndGames.build` ~398-448; `_GameCard._join` ~610-623)
- Test: `test/features/clubs/club_details_screen_test.dart`

- [ ] **Step 1: Update `_TablesAndGames.build` lookups**

Replace the `mine` / `mySeated` / `gamesByLabel` / overline / `_GameCard(...)` wiring. Specifically:

`mine` map — key by tableId:
```dart
    final mine = <String?, WaitlistEntry>{
      for (final e in (ref.watch(myWaitlistProvider).valueOrNull ?? const <WaitlistEntry>[])
          .where((e) => e.clubId == club.id))
        e.tableId: e,
    };
```

`mySeated` — set of tableIds the player is seated at:
```dart
    final mySeated = (ref.watch(mySessionProvider).valueOrNull ?? const <Session>[])
        .where((s) => s.clubId == club.id)
        .map((s) => s.tableId)
        .toSet();
```

Scoreboard map — key by tableId:
```dart
    final gamesByTableId = {for (final g in club.games) g.tableId: g};
```

Overline — show open-table count, not stake count:
```dart
          child: PsOverline('${l10n.liveGamesTitle} · ${openTables.length}'),
```
(Move the `openTables` computation above the `Column` return if needed; it is already computed at line ~426. Reorder so `openTables` is defined before the overline `Padding`.)

`_GameCard(...)` wiring:
```dart
          _GameCard(
            clubId: club.id,
            tableId: t.id,
            stakes: t.stakes,
            game: gamesByTableId[t.id],
            seatCount: t.seatCount,
            tableMinBuyIn: t.minBuyIn,
            tableAvgStack: t.avgStack,
            myEntry: mine[t.id],
            seated: mySeated.contains(t.id),
          ),
```

The early-return guard `if (byLabel.isEmpty)` can stay (it equals "no open tables"); leave `byLabel` only if still referenced, otherwise replace with `if (openTables.isEmpty)`. Use:
```dart
    if (openTables.isEmpty) {
      return _emptyState(l10n);
    }
```
and delete the now-unused `byLabel` map.

- [ ] **Step 2: Update `_GameCard._join` to pass tableId**

`lib/features/clubs/presentation/club_details_screen.dart`, `_join`:
```dart
    unawaited(ref.read(waitlistRepositoryProvider).join(
          clubId: clubId,
          tableId: tableId,
          playerUid: uid,
          playerName: user == null ? '' : '${user.firstName} ${user.lastName}'.trim(),
          stakes: stakes,
        ));
```

- [ ] **Step 3: Update the widget test**

`test/features/clubs/club_details_screen_test.dart` — the club doc's `games` must carry `tableId` matching the table, and the player's waitlist entry (if any) must carry the same `tableId`. Find where the test builds `ClubGame`/`Club.games` and add `tableId: 't1'` (matching the test table id). If the test asserts the overline text "· N stakes", update it to the open-table count. Run the test to discover exact assertions:

Run: `flutter test test/features/clubs/club_details_screen_test.dart`
Fix each failing expectation by aligning `tableId` on the test's `ClubGame` and waitlist fixtures with the table id used for `gameCard_<id>` / `joinGame_<id>`.

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/features/clubs/club_details_screen_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/clubs/presentation/club_details_screen.dart test/features/clubs/club_details_screen_test.dart
git commit -m "feat(clubs): player club-details reads scoreboard/waitlist per table"
```

---

## Task 9: Player reservation flow — reserve a specific table

The flow currently lets the player pick a *stake*. Change it to pick a *table* (one pill per open, reservable table) and pass that `tableId` to `reserve`.

**Files:**
- Modify: `lib/features/floor/presentation/reservation_flow_screen.dart`
- Test: `test/features/floor/reservation_flow_test.dart`

- [ ] **Step 1: Track the selected table instead of stake**

Change the state field:
```dart
class _ReservationFlowScreenState extends ConsumerState<ReservationFlowScreen> {
  PokerTable? _selected;
  bool _held = false;
  bool _busy = false;
```

- [ ] **Step 2: Reserve with the table's id + stakes**

```dart
  Future<void> _reserve(PokerTable table) async {
    setState(() => _busy = true);
    final uid = ref.read(authRepositoryProvider).currentUid;
    final user = ref.read(currentUserProvider).valueOrNull;
    if (uid != null) {
      await ref.read(reservationsRepositoryProvider).reserve(
            clubId: widget.clubId,
            tableId: table.id,
            playerUid: uid,
            playerName: user == null ? '' : '${user.firstName} ${user.lastName}'.trim(),
            stakes: table.stakes,
            durationMinutes: _reservationMinutes,
          );
    }
    if (mounted) setState(() => _held = true);
  }
```

- [ ] **Step 3: Build the reservable-table list per table**

Replace the `games`/`byLabel`/`reservable` block in `build` with a per-table version:
```dart
    final gamesByTableId = {for (final g in club?.games ?? const <ClubGame>[]) g.tableId: g};
    // A table is reservable when it has an OPEN seat, OR nobody is waiting for it
    // (a reservation has priority over a not-yet-formed queue). Blocked only when
    // there is no seat AND at least one person waits for that table.
    final reservable = <PokerTable>[
      for (final t in tables.where((t) => t.open))
        if ((gamesByTableId[t.id]?.openSeats ?? 0) > 0 || (gamesByTableId[t.id]?.waiting ?? 0) == 0) t,
    ];
    final reservableIds = reservable.map((t) => t.id).toSet();
    if (_selected != null && !reservableIds.contains(_selected!.id)) _selected = null;
    _selected ??= reservable.isNotEmpty ? reservable.first : null;
```

- [ ] **Step 4: Render one pill per table**

Replace the pills `Wrap` children:
```dart
                        for (final t in reservable)
                          PsFilterPill(
                            label: (gamesByTableId[t.id]?.openSeats ?? 0) > 0
                                ? '${l10n.tableLabel} ${t.number} · ${t.stakes.label} · ${gamesByTableId[t.id]!.openSeats} ${l10n.openShort}'
                                : '${l10n.tableLabel} ${t.number} · ${t.stakes.label}',
                            active: _selected?.id == t.id,
                            onTap: () => setState(() => _selected = t),
                          ),
```

And the reserve button:
```dart
                      onPressed: (_selected == null || _busy) ? null : () => unawaited(_reserve(_selected!)),
```

- [ ] **Step 5: Run the test, align fixtures**

Run: `flutter test test/features/floor/reservation_flow_test.dart`
The test builds a club with `games` and tables; add `tableId` to each `ClubGame` fixture matching its table, and update any pill-label assertion (now "Table N · …"). Re-run until PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/floor/presentation/reservation_flow_screen.dart test/features/floor/reservation_flow_test.dart
git commit -m "feat(floor): player reserves a specific table"
```

---

## Task 10: Pit game-detail — keyed by tableId (single table, own lists)

This is the largest UI change. The screen's identity becomes a single `tableId` (stable across blinds/variant edits). It shows one table, its own waitlist (filtered by `tableId`), and its own reservations (filtered by `tableId`). The "shared waitlist" note, the multi-table loop, the `_reopenWithLabel` dance, and the in-screen "add table" button all go away.

**Files:**
- Modify: `lib/features/floor/presentation/game_detail_screen.dart`
- Test: `test/features/floor/tables_ui_test.dart` (the GameDetail tests)

- [ ] **Step 1: Change the constructor to take a tableId**

```dart
class GameDetailScreen extends ConsumerWidget {
  const GameDetailScreen({super.key, required this.clubId, required this.tableId});
  final String clubId;
  final String tableId;
```

- [ ] **Step 2: Rewrite `build` to a single table + per-table filters**

Replace the body of `build` (the `final allTables ... return PsScaffold(...)` section) with:

```dart
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final allTables = ref.watch(tablesProvider(clubId)).valueOrNull ?? const <PokerTable>[];
    PokerTable? table;
    for (final t in allTables) {
      if (t.id == tableId) { table = t; break; }
    }
    // Table missing = still loading, or it was just deleted. Show a spinner; the
    // delete flow pops the screen itself.
    if (table == null) {
      return const PsScaffold(body: SafeArea(child: Center(child: CircularProgressIndicator())));
    }
    final t = table;
    final tables = [t]; // helpers below take a list; this game is exactly one table
    final sessions = ref.watch(clubSessionsProvider(clubId)).valueOrNull ?? const <Session>[];
    final waitlist = (ref.watch(clubWaitlistProvider(clubId)).valueOrNull ?? const <WaitlistEntry>[])
        .where((e) => e.tableId == tableId)
        .toList();
    final reservations =
        (ref.watch(clubReservationsProvider(clubId)).valueOrNull ?? const <Reservation>[])
            .where((r) => r.tableId == tableId && r.status == ReservationStatus.held)
            .toList();

    return PsScaffold(
      body: SafeArea(
        child: Column(
          children: [
            _nav(context, '${t.stakes.label} · ${l10n.tableLabel} ${t.number}'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(PsSpacing.s5),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: PsSpacing.s4),
                    child: _tableCard(context, ref, tables, 0, sessions),
                  ),
                  const SizedBox(height: PsSpacing.s2),
                  Row(
                    children: [
                      PsOverline('${l10n.waitlistTitle} · ${waitlist.length}'),
                      const Spacer(),
                      GestureDetector(
                        key: const Key('addWaitlistBtn'),
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _addToWaitlist(context, ref, t),
                        child: Text('+ ${l10n.addLabel}'.toUpperCase(),
                            style: const TextStyle(
                                fontSize: PsType.caption,
                                fontWeight: PsType.weightBlack,
                                letterSpacing: PsType.trackingWide,
                                color: PsColors.accentPrimary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: PsSpacing.s3),
                  ..._waitlistRows(context, ref, tables, waitlist, sessions),
                  if (reservations.isNotEmpty) ...[
                    const SizedBox(height: PsSpacing.s4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: PsOverline(
                          '${l10n.reservationsTitle} · ${reservations.length} ${l10n.heldLabel}'),
                    ),
                    const SizedBox(height: PsSpacing.s3),
                    for (final r in reservations)
                      _reservationRow(
                          context, ref, tables, sessions, _firstFreeSeat(tables, sessions), r),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
```

- [ ] **Step 3: Remove the multi-table "shared waitlist" note**

In `_tableCard`, delete the trailing `if (i > 0) Padding(... 'Waitlist · Table N' ...)` block (lines ~222-230). With one table there is never an `i > 0`.

- [ ] **Step 4: Drop blinds/variant re-open hops (tableId identity is stable)**

`tableId` no longer changes when blinds/variant change, so the screen need not re-open. In `_editBlinds`, remove the `_reopenWithLabel(nav, newLabel)` call and the `newLabel`/`nav` locals. In `_editVariant`'s save handler, remove `_reopenWithLabel(nav, newLabel)` and the `newLabel` local; keep `nav.pop()` (closes the sheet). Then delete the now-unused `_reopenWithLabel` method entirely.

`_editBlinds` becomes:
```dart
  Future<void> _editBlinds(
      BuildContext context, WidgetRef ref, List<PokerTable> tables, String v) async {
    final parts = v.split('/');
    final sb = parts.isNotEmpty ? num.tryParse(parts[0].trim()) : null;
    final bb = parts.length > 1 ? num.tryParse(parts[1].trim()) : null;
    if (sb == null || bb == null || tables.isEmpty) return;
    for (final t in tables) {
      await ref.read(tablesRepositoryProvider)
          .updateTable(t.copyWith(stakes: t.stakes.copyWith(smallBlind: sb, bigBlind: bb)));
    }
  }
```

In `_editVariant`'s `onPressed`, replace the tail:
```dart
                final nav = Navigator.of(ctx);
                for (final tt in tables) {
                  await ref.read(tablesRepositoryProvider).updateTable(PokerTable(
                        id: tt.id,
                        clubId: tt.clubId,
                        number: tt.number,
                        stakes: tt.stakes.copyWith(variant: finalVariant),
                        seatCount: tt.seatCount,
                        open: tt.open,
                        avgStack: tt.avgStack,
                        minBuyIn: tt.minBuyIn,
                        omahaPerCircle: per,
                        omahaVariant: ov,
                      ));
                }
                nav.pop(); // close the sheet
```
(remove the `final newLabel = ...` line and the `_reopenWithLabel(nav, newLabel);` line).

- [ ] **Step 5: Remove the in-screen "add table" button + `_addTable`**

The new build (Step 2) already omits the `addTableBtn`. Delete the `_addTable` method (lines ~825-838) since nothing calls it now. (New Game on the tables screen creates tables.)

- [ ] **Step 6: Pass tableId when adding a walk-in to the waitlist**

`_AddToWaitlistSheet` currently takes `stakes`. Give it `tableId` too. Change the widget:
```dart
class _AddToWaitlistSheet extends ConsumerStatefulWidget {
  const _AddToWaitlistSheet({required this.clubId, required this.tableId, required this.stakes});
  final String clubId;
  final String tableId;
  final Stakes stakes;
```
its `_join`:
```dart
  void _join(String playerUid, String name) {
    final nav = Navigator.of(context);
    unawaited(_surface(context, () => ref.read(waitlistRepositoryProvider).join(
          clubId: widget.clubId, tableId: widget.tableId, playerUid: playerUid, playerName: name,
          stakes: widget.stakes)));
    nav.pop();
  }
```
and the opener `_addToWaitlist`:
```dart
  void _addToWaitlist(BuildContext context, WidgetRef ref, PokerTable t) {
    PsSheet.show<void>(context, child: _AddToWaitlistSheet(clubId: clubId, tableId: t.id, stakes: t.stakes));
  }
```

- [ ] **Step 7: Filter the seat-picker's waiting list by tableId**

In `_SeatPickerSheetState.build`, replace the waiting filter:
```dart
    final waiting = (ref.watch(clubWaitlistProvider(widget.clubId)).valueOrNull ?? const <WaitlistEntry>[])
        .where((e) => e.tableId == widget.table.id)
        .where((e) => query.isEmpty || e.playerName.toLowerCase().contains(query))
        .where((e) => !GameDetailScreen.seatedAtTable(sessions, e.playerUid, widget.table.id))
        .toList();
```

- [ ] **Step 8: Update `_confirmDeleteTable` to cancel this table's waitlist**

The screen is now a single table, so deleting it always leaves the screen — and its own waitlist is always orphaned. Replace the `wasLast`/`stakeLabel` logic:
```dart
  Future<void> _confirmDeleteTable(
      BuildContext context, WidgetRef ref, List<PokerTable> tables, PokerTable t) async {
    final l10n = AppL10n.of(context);
    final nav = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteTable),
        content: Text(l10n.deleteTableConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.cancelWaitlist)),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(l10n.deleteTable)),
        ],
      ),
    );
    if (ok != true) return;
    // This table's own waitlist is now orphaned — cancel those entries.
    final waitlistToCancel =
        (ref.read(clubWaitlistProvider(clubId)).valueOrNull ?? const <WaitlistEntry>[])
            .where((e) => e.tableId == t.id)
            .toList();
    await deleteTableAndEndSessions(
      tablesRepo: ref.read(tablesRepositoryProvider),
      sessionsRepo: ref.read(sessionsRepositoryProvider),
      waitlistRepo: ref.read(waitlistRepositoryProvider),
      sessions: ref.read(clubSessionsProvider(clubId)).valueOrNull ?? const <Session>[],
      waitlistToCancel: waitlistToCancel,
      clubId: clubId,
      tableId: t.id,
    );
    nav.pop();
  }
```

- [ ] **Step 9: Update the GameDetail widget tests**

`test/features/floor/tables_ui_test.dart` — every `GameDetailScreen(clubId: 'vake', stakeLabel: 'NLH 1/2 GEL')` becomes `GameDetailScreen(clubId: 'vake', tableId: 't1')`. The waitlist/reservation fixtures must carry `tableId: 't1'` so they appear:
  - In the "waitlist row has Seat + remove" and "shared waitlist with a Seat action" tests, build `WaitlistEntry(... tableId: 't1', ...)`.
  - In the "held reservation" test, build `Reservation(... tableId: 't1', ...)`.
The `_table` const already has `id: 't1'`.

Run: `flutter test test/features/floor/tables_ui_test.dart`
Fix any remaining assertion (e.g. nav title now reads "NLH 1/2 GEL · Table 1"). Re-run until PASS.

- [ ] **Step 10: Commit**

```bash
git add lib/features/floor/presentation/game_detail_screen.dart test/features/floor/tables_ui_test.dart
git commit -m "feat(floor): Pit game-detail is per table (own waitlist + reservations)"
```

---

## Task 11: Pit tables-list — navigate + count per table

**Files:**
- Modify: `lib/features/floor/presentation/tables_screen.dart` (`waiting` helper ~72, `_TableCard` onTap ~180-184)
- Test: `test/features/floor/tables_ui_test.dart` (TablesScreen test)

- [ ] **Step 1: Count waiting per table**

Replace the `waiting` helper (line ~72):
```dart
    int waiting(String tableId) => waitlist.where((e) => e.tableId == tableId).length;
```
and its call site (line ~159):
```dart
                waiting: waiting(t.id),
```

- [ ] **Step 2: Navigate to the table's game detail**

`_TableCard.onTap` (line ~180):
```dart
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => GameDetailScreen(clubId: table.clubId, tableId: table.id),
        ),
      ),
```

- [ ] **Step 3: Run the test**

Run: `flutter test test/features/floor/tables_ui_test.dart`
Expected: PASS (the TablesScreen test asserts `tableCard_t1`, `1/9`, etc. — unaffected; only the `waiting` count source changed). If the TablesScreen test's waitlist fixture asserted a waiting count, give that entry `tableId: 't1'`.

- [ ] **Step 4: Commit**

```bash
git add lib/features/floor/presentation/tables_screen.dart test/features/floor/tables_ui_test.dart
git commit -m "feat(floor): Pit tables-list navigates + counts per table"
```

---

## Task 12: Full verification + deploy

**Files:** none (verification only)

- [ ] **Step 1: Analyze**

Run: `flutter analyze`
Expected: `No issues found!` Fix any unused-import / dead-code warnings left by removed helpers (`_reopenWithLabel`, `_addTable`, `byLabel`).

- [ ] **Step 2: Full test suite**

Run: `flutter test`
Expected: all pass. Likely fixture-touch test files beyond those already edited: `test/features/floor/waitlist_lifecycle_test.dart`, `test/features/floor/seated_at_table_test.dart`, `test/features/floor/floor_providers_test.dart`, `test/features/floor/my_waitlist_banner_test.dart`. For each failure, the cause is one of: (a) a `GameDetailScreen(stakeLabel:)` call → change to `tableId:`; (b) a waitlist/reservation fixture that must now carry a `tableId` to be visible; (c) a `ClubGame` fixture needing `tableId`. Fix and re-run.

- [ ] **Step 3: Goldens (if any changed)**

Run: `flutter test --update-goldens` only if a golden test fails purely from layout text (e.g. the reservation pill label). Inspect the diff first; do NOT blindly update if the change is unexpected.

- [ ] **Step 4: Commit any test fixups**

```bash
git add -A
git commit -m "test: align fixtures with per-table waitlist/reservation/scoreboard"
```

- [ ] **Step 5: Build + deploy (USER runs these)**

The user deploys (the harness blocks production deploys). Provide:
```
flutter build web
firebase deploy --only hosting,functions,firestore:rules --project pokerspot
```
`functions` MUST be deployed (recomputeClub / onReservationCreate / notifySeatOpen changed). `firestore:rules` unchanged this round but harmless to include.

- [ ] **Step 6: Manual smoke test on the deployed app**
  1. Open two NLH 5/10 tables (Table 1, Table 2).
  2. As a player: join Table 1's waitlist (when full) — confirm Table 2 still shows "join", not "waiting".
  3. As Pit: open Table 1 — its waitlist shows the player; open Table 2 — empty.
  4. Reserve Table 2 as a player — confirm the hold lands on Table 2 only.
  5. Delete Table 1 — confirm its waitlist clears and Table 2 is untouched.

---

## Self-Review

**Spec coverage:**
- Own waitlist per table → Tasks 1, 4, 6, 8, 10, 11 (tableId on entry; recompute per table; filter by tableId in player + Pit). ✓
- Own open-seat count per table → Task 6 (recomputeClub per table) + Task 8 (player reads `gamesByTableId[t.id]`). ✓ (Sessions already per-table.)
- Own reservations per table → Tasks 2, 5, 7, 9, 10 (tableId on reservation; reserve a table; seat at that table; Pit filters by tableId). ✓
- Same-stake tables behave like different-stake tables → guaranteed because all keys are now `tableId`, never `stakeKey`. ✓

**Placeholder scan:** No "TBD"/"handle edge cases"; every code step has complete code. Test tasks that depend on existing fixtures (Tasks 8/9/11/12) instruct running the test to surface exact assertions — this is concrete (run, read failure, align tableId), not a placeholder.

**Type consistency:**
- `tableId` is `String?` on `WaitlistEntry`/`Reservation` and on `join`/`reserve` params; `String` (default `''`) on `ClubGame`. Lookups `mine[t.id]` / `gamesByTableId[t.id]` use the table's non-null `String` id; map value types are `Map<String?, WaitlistEntry>` and `Map<String, ClubGame>` respectively — both accept a `String` key. ✓
- `GameDetailScreen` constructor field renamed `stakeLabel` → `tableId` (String) consistently in Tasks 10 + 11 + all tests. ✓
- Cloud Function reads `w.tableId` / `r.tableId` / `after.tableId`, all written by the Dart repos in Tasks 4/5 (and by `seat`/`seatPlayer`/`holdSeat`, which already write `tableId` on sessions). ✓

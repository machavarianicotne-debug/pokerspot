# Clubs — Player View Implementation Plan (Plan 3)

> Executed task-by-task; one atomic commit per task. Builds on Plan 1 (foundation) + Plan 2 (auth/role routing). Player lands on `/home` → Clubs list → Club details.

**Goal:** A signed-in Player sees a list of enabled poker clubs and can open a club's details (address, hours, tappable phone). Data from Firestore `clubs/` (read-only for players). Web-first; live at https://pokerspot.web.app.

**Architecture:** Feature-first Clean Architecture (spec §12). `features/clubs/{domain,data,presentation}`. Repository pattern: `ClubsRepository` interface + `FakeClubsRepository` (tests) + `FirebaseClubsRepository` (runtime). Riverpod providers wire them. `go_router` route `/home/club/:id`. `photoUrl` is a plain string (nullable) — **no Firebase Storage in this plan** (image upload = future plan if needed).

**Tech Stack:** `cloud_firestore`, `flutter_riverpod`, `go_router`, `url_launcher` (tel:), `flutter_test` + fakes.

**Locked:** all Plan 1 + Plan 2 files EXCEPT `lib/app/router.dart` (add route + wire PlayerHome) and `lib/features/home/presentation/player_home.dart` (PlayerHome body → ClubsListScreen; `RoleScaffold` unchanged for PitBoss/SuperAdmin).

---

## Task 1: Club model + ClubsRepository interface
- Create `lib/features/clubs/domain/club.dart`: `Club` (id, name, city, address, `String? photoUrl`, hoursText, phone, `bool enabled`). Pure Dart. `==`, `hashCode`, `copyWith`, `fromMap(id, map)` (defaults: strings `''`, photoUrl `null`, enabled `false`), `toMap()` (no id). ID = Firestore doc id.
- Create `lib/features/clubs/domain/clubs_repository.dart`: abstract `ClubsRepository` — `Stream<List<Club>> watchEnabledClubs()`, `Stream<Club?> watchClub(String id)`, `Future<Club?> getClub(String id)`. No Firebase types leak.
- Test `test/features/clubs/club_test.dart`: fromMap/toMap round-trip, defaults, ==/hashCode, copyWith.
- **Accept:** analyze clean, tests green, no Firebase imports in domain.

## Task 2: Fake + Firebase clubs repositories
- `lib/features/clubs/data/fake_clubs_repository.dart`: in-memory `Map<String, Club>` + per-id broadcast controllers + a list controller. `watchEnabledClubs` emits enabled-only, replays current on subscribe. Seeding ctor arg.
- `lib/features/clubs/data/firebase_clubs_repository.dart`: DI `final FirebaseFirestore _firestore`; `clubs/` collection; `watchEnabledClubs` = `where('enabled', isEqualTo: true).snapshots()` mapped to `Club.fromMap(doc.id, doc.data())`; `watchClub`/`getClub` by doc id. Not unit-tested.
- Test `test/features/clubs/fake_clubs_repository_test.dart`: enabled filter, watchClub emits, getClub.
- **Accept:** analyze clean, tests green.

## Task 3: Riverpod providers
- `lib/features/clubs/presentation/providers.dart`: `clubsRepositoryProvider` → `FirebaseClubsRepository(FirebaseFirestore.instance)`; `clubsListProvider` `StreamProvider<List<Club>>` (watchEnabledClubs); `clubProvider` `StreamProvider.family<Club?, String>` (watchClub).
- Test `test/features/clubs/clubs_providers_test.dart`: clubsListProvider reflects fake (override).
- **Accept:** analyze clean, tests green.

## Task 4: ClubsListScreen (embedded widget)
- `lib/features/clubs/presentation/clubs_list_screen.dart`: `ConsumerWidget`, watches `clubsListProvider`; `.when` loading→`CircularProgressIndicator`, empty→`noClubsYet`, data→`ListView` of `Card`s (thumbnail: `photoUrl` image or icon fallback; name + city). Wrapped in `CenteredPane`. Tap → `context.go('/home/club/${club.id}')`.
- Test `test/features/clubs/clubs_list_screen_test.dart`: loading (override never-emit), empty, data (names+cities), tap→navigates (GoRouter), responsive 375/1280.
- **Accept:** analyze clean, tests green.

## Task 5: ClubDetailsScreen + url_launcher
- `flutter pub add url_launcher` (compatible version; STOP if warns).
- `lib/features/clubs/presentation/club_details_screen.dart`: `ConsumerWidget`, `final String clubId`; watches `clubProvider(clubId)`; full Scaffold + AppBar (back → `context.go('/home')`, `backToClubs` tooltip); hero header (photo or fallback icon), name, city, `clubAddress`+address, `clubHours`+hoursText, tappable `clubPhone`+phone (`launchUrl(Uri.parse('tel:...'))`); `tablesComingSoon` card. Null/loading handled.
- Test `test/features/clubs/club_details_screen_test.dart`: renders club fields; tables placeholder; (tel launch not asserted — plugin).
- **Accept:** analyze clean, tests green.

## Task 6: Router + PlayerHome wire
- `lib/app/router.dart`: add `GoRoute(path: '/home/club/:id', builder: (ctx, st) => ClubDetailsScreen(clubId: st.pathParameters['id']!))`.
- `lib/features/home/presentation/player_home.dart`: `PlayerHome` → `ConsumerWidget` Scaffold (AppBar title `clubsListTitle` + sign-out) with body `ClubsListScreen()`. `RoleScaffold` unchanged.
- **Accept:** smoke test green, analyze clean, all tests green.

## Task 7: l10n keys
- Add to en/ka/ru ARBs: `clubsListTitle`, `noClubsYet`, `clubAddress`, `clubHours`, `clubPhone`, `tablesComingSoon`, `backToClubs`. `flutter gen-l10n`.
- **Accept:** analyze clean, tests green.

## Task 8: README (clubs schema + 4 demo clubs) + deploy
- README: document `clubs/` schema (field → type) + "add a club via Firestore Console" walkthrough + a paste-ready block for 4 demo clubs:
  - PokerSpot Vake — Tbilisi — Chavchavadze Ave 47
  - PokerSpot Saburtalo — Tbilisi — Vazha-Pshavela Ave 76
  - Aragvi Club — Tbilisi — Rustaveli Ave 12
  - Batumi Royal — Batumi — Memed Abashidze Ave 25
  - all: hoursText "Daily 14:00–04:00", phone "+995 32 200 0000", photoUrl null, enabled true.
- `flutter build web --dart-define-from-file=env-dev.json` → `firebase deploy --only hosting` → confirm HTTP 200. STOP on credential error.

---

## Notes / decisions
- `photoUrl` string-only; no Storage (future plan).
- Players read clubs; writing/managing clubs = Super Admin (later plan). Security rules deferred to Plan 7.
- Clubs list capped at 440px (CenteredPane) for the phone-frame feel, consistent with auth screens.

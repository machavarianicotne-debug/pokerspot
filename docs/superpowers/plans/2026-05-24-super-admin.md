# Plan 6 — Super Admin

> Autonomous run. Simplest correct, gated, Liquid Sport, reuse `Ps*`.

**Goal:** Give the owner (Super Admin) the tools to run the network: clubs CRUD,
staff assignment, user management, per-club analytics, all audited.

**Architecture:** Extend `ClubsRepository` (CRUD + watch-all), `UsersRepository`
(watch-all + role/blocked/clubId mutations) and `SessionsRepository`
(`watchAllByClub` for analytics). New `features/admin/` with an
`AdminRepository` writing `admin_audit_log/{id}` (+ `AuditEntry` model). Super
Admin UI replaces the `RoleScaffold` stub tabs.

## Data model
- `clubs/{id}` — existing fields; CRUD added; `enabled` toggled.
- `users/{uid}` — `role`, `blocked`, `clubId` mutated by admin.
- `admin_audit_log/{id}` (new, top-level): `actorUid`, `action`, `target`,
  `meta` (map), `at` (serverTimestamp).

## Tabs (RoleScaffold → Super Admin)
Overview (aggregates) · Clubs (CRUD + analytics) · Users (search/role/ban/assign) · Profile.

## Tasks
1. doc (this file).
2. Repo layer — Clubs CRUD + `watchAllClubs`; Users `watchAllUsers` +
   `updateRole`/`setBlocked`/`assignClub`; Sessions `watchAllByClub`; Admin repo
   + `AuditEntry`; Fake + Firebase; Fake unit tests.
3. Providers — `allClubsProvider`, `allUsersProvider`, `adminRepositoryProvider`,
   `clubSessionsAllProvider`.
4. UI — `AdminOverviewScreen`, `AdminClubsScreen` (+ `ClubEditorSheet`,
   `ClubAnalyticsScreen`), `AdminUsersScreen` (role pills, ban toggle, assign
   club); audit-log every mutation; wire into `RoleScaffold`.
5. l10n (en/ka/ru) + gen-l10n.
6. Cleanup — delete `tools/seed_clubs.*` and `tools/setup_test_users.*`.

## Deferred (heavy/observe-only — not in the 5-item scope)
Observe-club / observe-table read-only screens, app-wide settings screen, audit
log viewer UI (entries are still written). 7-day trend charts (show flat counts).

## Gate
analyze clean + tests green per commit; single `firebase deploy` at plan end.

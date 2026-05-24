# Plan 7 — Cloud Functions, Security Rules, Push

> Autonomous run. Executed in the blocker-minimizing order: **B → D → A → C**.

**Goal:** Lock down Firestore with production rules, add server-side automation
(Cloud Functions), push notifications, and re-enable the service worker with a
proper update UX.

## Order (minimizes blocker time)
- **B — firestore.rules** (no Blaze): role/club-scoped production rules replacing
  test mode (expires 2026-06-23). Deploy `firebase deploy --only firestore:rules`.
- **SW re-enable** — `web/index.html`: register the Flutter SW with a
  "new version → reload" toast (SkipWaiting + reload). Deferred from Design Polish.
- **D — in-club chat** (OPTIONAL): `messages/{clubId}/messages/{msgId}`.
  **Deferred** in this run (running long) — rules already provision the path.
- **A — Cloud Functions** (triggers Blaze STOP): (a) scheduled expire of waitlist
  entries past a call deadline, (b) `called` → FCM fan-out, (c) `session.endedAt`
  → `admin_audit_log`. Code committed; `firebase deploy --only functions`
  requires the **Blaze** upgrade → STOP.
- **C — Push** (firebase_messaging, web first): requires a **VAPID key** → STOP.

## Rules model (no custom claims yet — read users/{uid})
- Players: read enabled clubs; create/read/cancel own waitlist; read own sessions.
- Pit Boss: read/write own-club (`users/{uid}.clubId`) tables/waitlist/sessions.
- Super Admin: full access; only role that writes clubs + audit log.
- Blocked users (`blocked == true`): denied writes everywhere.

## STOP conditions (per the run order)
- Plan 7-A → Blaze upgrade. Plan 7-C → FCM VAPID key. (Both surfaced verbatim.)

## Gate
analyze clean + tests green per commit; `firebase deploy --only firestore:rules`
+ hosting at plan stages.

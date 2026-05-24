# PokerSpot

Tbilisi poker-rooms app (Flutter + Firebase). Liquid Sport design system.
Android-first; minSdk 23. Tested on a real device (no emulator).

## One-time: Android SDK (required for device run / APK)
This machine has the Flutter SDK but **no Android SDK yet**. Install it once:
1. Install Android Studio (bundles the SDK) or the Android command-line tools.
2. Set `ANDROID_HOME` to the SDK path (e.g. `C:\Users\user\AppData\Local\Android\Sdk`).
3. `flutter doctor --android-licenses` → accept all.
4. `flutter doctor` → the "Android toolchain" line should be a green check.

## Run on a connected Android phone
1. Phone: enable Developer options (tap Build number x7) → enable USB debugging.
2. Connect via USB, accept "Trust this computer".
3. `flutter devices`  → confirm the phone is listed.
4. `flutter run -d <device-id> --dart-define-from-file=env-dev.json`

## Shareable APK (for test users)
`flutter build apk --release --dart-define-from-file=env-dev.json`
→ `build/app/outputs/flutter-apk/app-release.apk` (send via WhatsApp/Telegram).

## Dev
- Tests: `flutter test`   ·   Lint: `flutter analyze`   ·   Web check: `flutter run -d chrome --dart-define-from-file=env-dev.json`
- Environments: `env-dev.json` (default) / `env-prod.json`.

## Auth (web-first, Plan 2)
- Run locally: `flutter run -d chrome --dart-define-from-file=env-dev.json`
- Live URL (shareable): https://pokerspot.web.app  (deploy: `flutter build web --dart-define-from-file=env-dev.json && firebase deploy --only hosting`)
- Test phone numbers (Firebase Console → Auth → Phone): 555 11 11 11→111111, …66 66 66→666666.
- Responsive: works at 375px (Chrome DevTools mobile) and 1280px (centered 440px pane).

### Become Super Admin (one-time seed)
1. Sign in with +995 555 11 11 11 / 111111, complete onboarding (you're a Player).
2. Firebase Console → Firestore → `users/<your-uid>` → set `role` = `superadmin`.
3. Reload the app — you now land on the Super Admin home.

## Clubs (Plan 3) — Firestore `clubs/` collection

A signed-in Player sees enabled clubs on the home screen and can open a club's
details. Clubs are read-only for players; seed them manually in the Firebase
Console for now (Super Admin club management is a later plan).

### Schema — collection `clubs`, one document per club
| Field | Type | Notes |
|---|---|---|
| `name` | string | Club name (shown in list + details) |
| `city` | string | e.g. `Tbilisi`, `Batumi` |
| `address` | string | Street address |
| `photoUrl` | string \| null | Image URL; leave empty/omit for the icon fallback (no upload yet) |
| `hoursText` | string | Free text, e.g. `Daily 14:00–04:00` |
| `phone` | string | Tappable (`tel:`) in details |
| `enabled` | boolean | **Only `true` clubs appear to players** |

The Firestore **document id** is the club id (used in the URL `/home/club/<id>`).
You can let the Console auto-generate the id.

### Add a club via the Firebase Console
1. Firebase Console → **Firestore Database** → **Start collection** (first time)
   with collection id `clubs`; afterwards use **Add document**.
2. **Auto-ID** the document.
3. Add the fields from the table above (set `enabled` as type **boolean** = `true`;
   set `photoUrl` to a string or just omit it).
4. Save. Reload the app — the club shows up in the Players' list immediately
   (live via Firestore snapshots).

### Demo clubs to seed (paste field-by-field)
Create one `clubs` document per block below (all `enabled: true`, `photoUrl` omitted):
```jsonc
// doc 1
{ "name": "PokerSpot Vake",      "city": "Tbilisi", "address": "Chavchavadze Ave 47",     "hoursText": "Daily 14:00–04:00", "phone": "+995 32 200 0001", "enabled": true }
// doc 2
{ "name": "PokerSpot Saburtalo", "city": "Tbilisi", "address": "Vazha-Pshavela Ave 76",   "hoursText": "Daily 14:00–04:00", "phone": "+995 32 200 0002", "enabled": true }
// doc 3
{ "name": "Aragvi Club",         "city": "Tbilisi", "address": "Rustaveli Ave 12",        "hoursText": "Daily 14:00–04:00", "phone": "+995 32 200 0003", "enabled": true }
// doc 4
{ "name": "Batumi Royal",        "city": "Batumi",  "address": "Memed Abashidze Ave 25",  "hoursText": "Daily 14:00–04:00", "phone": "+995 32 200 0004", "enabled": true }
```

Reservations, waitlist, and sessions land in subsequent plans
(`docs/superpowers/plans/`).

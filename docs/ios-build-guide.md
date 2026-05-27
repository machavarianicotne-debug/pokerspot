# PokerSpot — iOS build guide (Windows + Apple Developer account, no Mac)

> Goal: install the app on an iPhone. You have Windows + a paid Apple Developer
> account. iOS apps can't be sideloaded like an Android APK — they install via
> **TestFlight** (or the App Store). With a cloud Mac (**Codemagic**) you can
> build + sign + ship to TestFlight **without owning a Mac**.

## What's done
- ✅ iOS platform added (`ios/`), bundle id **com.pokerspot.pokerspot** (matches Android).
- ✅ `codemagic.yaml` (cloud-Mac build → TestFlight) committed at repo root.

## Prerequisites (one-time)

### 1. Git remote (Codemagic builds from Git)
Push the repo to GitHub (or GitLab/Bitbucket):
```
git remote add origin <your-repo-url>
git push -u origin main
```

### 2. Firebase iOS
- Firebase console → Project settings → the iOS app already exists (appId in
  `firebase.json`). Download **GoogleService-Info.plist** → put in `ios/Runner/`.
- App init already uses `firebase_options.dart` (FlutterFire), so core works.
- For **push (APNs)**: Apple Developer → create an **APNs Auth Key (.p8)** →
  upload in Firebase console → Cloud Messaging → Apple app config.

### 3. Apple Developer / App Store Connect
- Register bundle id **com.pokerspot.pokerspot** as an App ID (or let the
  App Store Connect API key auto-manage it).
- Create the app in **App Store Connect** (name, bundle id).
- App Store Connect → Users and Access → **Integrations** → create an
  **API key** (.p8 + key id + issuer id) — Codemagic uses this to sign + upload.

### 4. Codemagic
- Sign up at codemagic.io (free tier), connect the Git repo.
- Team → Integrations → **App Store Connect**: add the API key from step 3,
  name the integration (use that name in `codemagic.yaml` → `APP_STORE_CONNECT_KEY`).
- Start a build of the **ios-testflight** workflow.

## Result
Codemagic compiles on macOS, signs, and uploads to **TestFlight**. On your
iPhone: install the **TestFlight** app → accept the build → install. Updates =
new Codemagic build → appears in TestFlight.

## Notes
- Web + iOS coexist: web via `flutter build web` + Firebase Hosting; iOS via
  Codemagic → TestFlight. Same codebase.
- App Store **review** (public release) is separate — see
  `app-store-submission-checklist.md` (account deletion ✅ already added,
  privacy policy + labels, age rating 17+, demo test phone, "venue management,
  no real-money gaming").
- Emoji quality on iOS = native Apple emojis (WhatsApp-level) automatically.

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

Foundation only — auth, clubs, and the rest land in subsequent plans
(`docs/superpowers/plans/`).

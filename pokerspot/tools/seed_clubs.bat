@echo off
REM Seed the 4 demo clubs into Firestore (idempotent; fixed doc ids).
REM cd to the pokerspot project root so the relative paths resolve.
cd /d "%~dp0.."
flutter run -t tools/seed_clubs.dart -d chrome --dart-define-from-file=env-dev.json

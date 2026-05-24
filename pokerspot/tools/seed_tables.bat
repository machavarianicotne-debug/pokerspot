@echo off
REM Seed demo tables into clubs/*/tables (idempotent; fixed doc ids).
REM Run tools/seed_clubs.bat first so the clubs exist.
cd /d "%~dp0.."
flutter run -t tools/seed_tables.dart -d chrome --dart-define-from-file=env-dev.json

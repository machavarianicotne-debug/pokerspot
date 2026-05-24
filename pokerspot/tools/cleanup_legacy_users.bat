@echo off
REM Delete legacy users/ docs with an empty phone (pre-phone-backfill onboardings).
REM Scans first; you must click "Delete all" in the page to actually delete.
cd /d "%~dp0.."
flutter run -t tools/cleanup_legacy_users.dart -d chrome --dart-define-from-file=env-dev.json

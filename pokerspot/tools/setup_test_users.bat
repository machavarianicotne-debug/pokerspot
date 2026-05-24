@echo off
REM Wire test phones to roles/clubs in users/ (idempotent). Sign in + onboard
REM with each test phone once first, so their user docs carry the phone.
cd /d "%~dp0.."
flutter run -t tools/setup_test_users.dart -d chrome --dart-define-from-file=env-dev.json

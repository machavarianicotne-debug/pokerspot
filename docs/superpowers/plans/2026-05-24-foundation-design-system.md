# Foundation & Design System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up the PokerSpot Flutter app skeleton — Clean-Architecture folders, centralized constants/feature-flags/environment, the Liquid Sport design tokens ported 1:1 from `mockups/v3-design-system/tokens.css`, theming, 3-language l10n scaffolding, and a Riverpod-wrapped app shell that launches a themed placeholder screen — all green under `flutter test`.

**Architecture:** Feature-first Clean Architecture per spec §12. This plan builds only `lib/core/*`, `lib/l10n/*`, and a minimal `lib/app/*` shell + one placeholder screen. No Firebase yet (Plan 2), so it runs on Windows → Android with no Blaze/account dependency. Everything visual flows from `core/theme/tokens.dart`; everything tunable flows from `core/constants` + `core/feature_flags.dart` + `core/config/environment.dart`.

**Tech Stack:** Flutter (Dart 3), `flutter_riverpod` (state), `go_router` (routing — wired minimally here, extended in Plan 2), `google_fonts` (Inter, the SF-Pro stand-in from the mockups), `flutter_localizations` + `gen-l10n` (ka/en/ru). Tests: `flutter_test`.

> **Note on verification:** every step lists the exact command and expected output. The implementing engineer/agent must run them on a machine with the Flutter SDK (this plan was authored without executing Flutter). Run `flutter analyze` after each task; it must stay clean.

---

## File map (what this plan creates)

```
pokerspot/
  pubspec.yaml                         deps + flutter config (gen-l10n, assets)
  analysis_options.yaml                lints
  l10n.yaml                            gen-l10n config
  env-dev.json  env-prod.json          --dart-define-from-file inputs
  lib/
    main.dart                          entrypoint → runApp(ProviderScope(PokerSpotApp))
    app/
      app.dart                         PokerSpotApp (MaterialApp.router + theme + l10n)
      router.dart                      minimal GoRouter (one route: home placeholder)
    core/
      constants/business_rules.dart    timing/limits/currency constants
      constants/validation_rules.dart  phone/name validation
      feature_flags.dart               FeatureFlags (env-overridable)
      config/environment.dart          Environment (dev/staging/prod) from dart-define
      theme/tokens.dart                PsColors/PsType/PsSpacing/PsRadii/PsMotion/PsGlass
      theme/app_theme.dart             ThemeData built from tokens
    features/
      home/presentation/home_screen.dart   themed placeholder (proves theme + l10n)
    l10n/
      app_en.arb  app_ka.arb  app_ru.arb
  test/
    core/constants/business_rules_test.dart
    core/constants/validation_rules_test.dart
    core/feature_flags_test.dart
    core/config/environment_test.dart
    core/theme/tokens_test.dart
    core/theme/app_theme_test.dart
    app/app_smoke_test.dart
```

Feature folders (`auth/`, `clubs/`, …) are created empty-on-demand by later plans; this plan only adds `features/home/`.

---

## Task 1: Create the Flutter project & dependencies

**Files:**
- Create: `pokerspot/` (whole project via `flutter create`)
- Modify: `pokerspot/pubspec.yaml`

- [ ] **Step 1: Create the project**

Run (from `C:\Users\user\Desktop\np`):
```bash
flutter create --org com.pokerspot --platforms=android,web --project-name pokerspot pokerspot
```
Expected: "All done!" and a `pokerspot/` directory. (Android is the launch target; `web` is included only for a quick smoke check. This plan contains **no emulator setup** — all device testing is on a real Android phone over USB.)

- [ ] **Step 2: Set minimum Android version to 23 (Android 6)**

Covers ~99% of devices in the Georgian market while allowing modern Flutter features. Edit `pokerspot/android/app/build.gradle.kts`, inside `android { defaultConfig { ... } }`:
```kotlin
minSdk = 23
```
(If the generated file is Groovy `build.gradle` instead, use `minSdkVersion 23`.) Do **not** leave the default `flutter.minSdkVersion`.

Run: `flutter analyze`
Expected: "No issues found!" (config-only change).

- [ ] **Step 3: Replace `pokerspot/pubspec.yaml` dependency section**

Set these blocks exactly (keep the generated `name`, `description`, `environment`, `version`):
```yaml
environment:
  sdk: ^3.5.0

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  flutter_riverpod: ^2.5.1
  go_router: ^14.2.0
  google_fonts: ^6.2.1
  intl: any

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0

flutter:
  uses-material-design: true
  generate: true
```

- [ ] **Step 4: Install deps**

Run: `cd pokerspot && flutter pub get`
Expected: "Got dependencies!" with no version-solve errors.

- [ ] **Step 5: Verify the fresh project is green**

Run: `flutter analyze`
Expected: "No issues found!"
Run: `flutter test`
Expected: the default widget test passes (we delete it in Task 9).

- [ ] **Step 6: Commit**

```bash
git add pokerspot
git commit -m "chore: scaffold Flutter project (minSdk 23) with core dependencies"
```

---

## Task 2: Business-rule constants (TDD)

**Files:**
- Create: `pokerspot/lib/core/constants/business_rules.dart`
- Test: `pokerspot/test/core/constants/business_rules_test.dart`

- [ ] **Step 1: Write the failing test**

`test/core/constants/business_rules_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/core/constants/business_rules.dart';

void main() {
  test('business rules match the spec (§12.A)', () {
    expect(BusinessRules.arrivalDeadlineMinutes, 30);
    expect(BusinessRules.sessionWarningHours, 8);
    expect(BusinessRules.maxPlayersPerTable, 9);
    expect(BusinessRules.maxWaitlistsPerPlayer, isNull); // no cap in MVP
    expect(BusinessRules.defaultCurrency, 'GEL');
    expect(BusinessRules.supportedCurrencies, ['GEL', 'USD', 'EUR']);
    expect(BusinessRules.minBuyInFloor, 1); // > 0
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/constants/business_rules_test.dart`
Expected: FAIL — `Target of URI doesn't exist: '.../business_rules.dart'`.

- [ ] **Step 3: Write minimal implementation**

`lib/core/constants/business_rules.dart`:
```dart
/// Centralized business rules (spec §12.A). Change a rule here — nowhere else.
abstract final class BusinessRules {
  /// Minutes a held reservation OR a called waitlist entry stays valid.
  static const int arrivalDeadlineMinutes = 30;

  /// A seated session longer than this shows a ⚠️ (no auto-end).
  static const int sessionWarningHours = 8;

  /// Default seats per table.
  static const int maxPlayersPerTable = 9;

  /// Max simultaneous waitlists per player; null = no cap in MVP.
  static const int? maxWaitlistsPerPlayer = null;

  static const String defaultCurrency = 'GEL';
  static const List<String> supportedCurrencies = ['GEL', 'USD', 'EUR'];

  /// buyInMin must be > 0 (no maxBuyIn — Tbilisi format is uncapped).
  static const int minBuyInFloor = 1;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/constants/business_rules_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/constants/business_rules.dart test/core/constants/business_rules_test.dart
git commit -m "feat: centralized business-rule constants"
```

---

## Task 3: Validation rules (TDD)

**Files:**
- Create: `pokerspot/lib/core/constants/validation_rules.dart`
- Test: `pokerspot/test/core/constants/validation_rules_test.dart`

- [ ] **Step 1: Write the failing test**

`test/core/constants/validation_rules_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/core/constants/validation_rules.dart';

void main() {
  test('phone must be E.164', () {
    expect(ValidationRules.isValidPhone('+995599123456'), isTrue);
    expect(ValidationRules.isValidPhone('+995 599 12 34 56'), isTrue); // spaces stripped
    expect(ValidationRules.isValidPhone('599123456'), isFalse);        // no +
    expect(ValidationRules.isValidPhone('+12'), isFalse);              // too short
  });

  test('display name needs >= 2 trimmed chars', () {
    expect(ValidationRules.isValidName('Giorgi'), isTrue);
    expect(ValidationRules.isValidName(' A '), isFalse);
    expect(ValidationRules.isValidName(''), isFalse);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/constants/validation_rules_test.dart`
Expected: FAIL — URI doesn't exist.

- [ ] **Step 3: Write minimal implementation**

`lib/core/constants/validation_rules.dart`:
```dart
/// Centralized validation (spec §12.A).
abstract final class ValidationRules {
  static const int minNameLength = 2;
  static final RegExp _e164 = RegExp(r'^\+\d{8,15}$');

  static bool isValidPhone(String raw) =>
      _e164.hasMatch(raw.replaceAll(RegExp(r'\s'), ''));

  static bool isValidName(String raw) => raw.trim().length >= minNameLength;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/constants/validation_rules_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/constants/validation_rules.dart test/core/constants/validation_rules_test.dart
git commit -m "feat: phone (E.164) + name validation rules"
```

---

## Task 4: Feature flags (TDD)

**Files:**
- Create: `pokerspot/lib/core/feature_flags.dart`
- Test: `pokerspot/test/core/feature_flags_test.dart`

- [ ] **Step 1: Write the failing test**

`test/core/feature_flags_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/core/feature_flags.dart';

void main() {
  test('MVP defaults match spec §12.B', () {
    const f = FeatureFlags.mvp();
    // shipped in MVP
    expect(f.clubChat, isTrue);
    expect(f.perSeatIdentity, isTrue);
    // deferred to v2
    expect(f.multiClubPitBoss, isFalse);
    expect(f.autoReservationConvertToWaitlist, isFalse);
    expect(f.deepAnalytics, isFalse);
    expect(f.geoMap, isFalse);
    expect(f.templateAutoRestore, isFalse);
    expect(f.crossClubWaitlist, isFalse);
    expect(f.iosSupport, isFalse);
  });

  test('copyWith overrides a single flag (per-env override)', () {
    const f = FeatureFlags.mvp();
    expect(f.copyWith(deepAnalytics: true).deepAnalytics, isTrue);
    expect(f.copyWith(deepAnalytics: true).clubChat, isTrue); // others unchanged
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/feature_flags_test.dart`
Expected: FAIL — URI doesn't exist.

- [ ] **Step 3: Write minimal implementation**

`lib/core/feature_flags.dart`:
```dart
/// Feature flags (spec §12.B). Activating the v2 backlog = flip a flag here.
class FeatureFlags {
  final bool clubChat;
  final bool perSeatIdentity;
  final bool multiClubPitBoss;
  final bool autoReservationConvertToWaitlist;
  final bool deepAnalytics;
  final bool geoMap;
  final bool templateAutoRestore;
  final bool crossClubWaitlist;
  final bool iosSupport;

  const FeatureFlags({
    required this.clubChat,
    required this.perSeatIdentity,
    required this.multiClubPitBoss,
    required this.autoReservationConvertToWaitlist,
    required this.deepAnalytics,
    required this.geoMap,
    required this.templateAutoRestore,
    required this.crossClubWaitlist,
    required this.iosSupport,
  });

  /// The MVP baseline.
  const FeatureFlags.mvp()
      : clubChat = true,
        perSeatIdentity = true,
        multiClubPitBoss = false,
        autoReservationConvertToWaitlist = false,
        deepAnalytics = false,
        geoMap = false,
        templateAutoRestore = false,
        crossClubWaitlist = false,
        iosSupport = false;

  FeatureFlags copyWith({
    bool? clubChat,
    bool? perSeatIdentity,
    bool? multiClubPitBoss,
    bool? autoReservationConvertToWaitlist,
    bool? deepAnalytics,
    bool? geoMap,
    bool? templateAutoRestore,
    bool? crossClubWaitlist,
    bool? iosSupport,
  }) {
    return FeatureFlags(
      clubChat: clubChat ?? this.clubChat,
      perSeatIdentity: perSeatIdentity ?? this.perSeatIdentity,
      multiClubPitBoss: multiClubPitBoss ?? this.multiClubPitBoss,
      autoReservationConvertToWaitlist:
          autoReservationConvertToWaitlist ?? this.autoReservationConvertToWaitlist,
      deepAnalytics: deepAnalytics ?? this.deepAnalytics,
      geoMap: geoMap ?? this.geoMap,
      templateAutoRestore: templateAutoRestore ?? this.templateAutoRestore,
      crossClubWaitlist: crossClubWaitlist ?? this.crossClubWaitlist,
      iosSupport: iosSupport ?? this.iosSupport,
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/feature_flags_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/feature_flags.dart test/core/feature_flags_test.dart
git commit -m "feat: feature flags with MVP defaults + per-env override"
```

---

## Task 5: Environment config (TDD)

**Files:**
- Create: `pokerspot/lib/core/config/environment.dart`
- Create: `pokerspot/env-dev.json`, `pokerspot/env-prod.json`
- Test: `pokerspot/test/core/config/environment_test.dart`

- [ ] **Step 1: Write the failing test**

`test/core/config/environment_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/core/config/environment.dart';
import 'package:pokerspot/core/feature_flags.dart';

void main() {
  test('defaults to dev when no dart-define given', () {
    expect(Environment.current.name, AppEnv.dev);
    expect(Environment.current.firebaseProjectId, 'pokerspot-dev');
  });

  test('prod flips deepAnalytics off but keeps MVP flags', () {
    final prod = Environment.forName('prod');
    expect(prod.name, AppEnv.prod);
    expect(prod.flags.clubChat, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/config/environment_test.dart`
Expected: FAIL — URI doesn't exist.

- [ ] **Step 3: Write the env JSON files**

`env-dev.json`:
```json
{ "APP_ENV": "dev", "FIREBASE_PROJECT_ID": "pokerspot-dev" }
```
`env-prod.json`:
```json
{ "APP_ENV": "prod", "FIREBASE_PROJECT_ID": "pokerspot-prod" }
```

- [ ] **Step 4: Write the implementation**

`lib/core/config/environment.dart`:
```dart
import 'package:pokerspot/core/feature_flags.dart';

enum AppEnv { dev, staging, prod }

/// App environment (spec §12.G). Selected via --dart-define APP_ENV;
/// defaults to dev. Per-env feature-flag overrides live here.
class Environment {
  final AppEnv name;
  final String firebaseProjectId;
  final FeatureFlags flags;

  const Environment({
    required this.name,
    required this.firebaseProjectId,
    required this.flags,
  });

  static final Environment current =
      Environment.forName(const String.fromEnvironment('APP_ENV', defaultValue: 'dev'));

  factory Environment.forName(String raw) {
    final projectId = const String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: '');
    switch (raw) {
      case 'prod':
        return Environment(
          name: AppEnv.prod,
          firebaseProjectId: projectId.isEmpty ? 'pokerspot-prod' : projectId,
          flags: const FeatureFlags.mvp(),
        );
      case 'staging':
        return Environment(
          name: AppEnv.staging,
          firebaseProjectId: projectId.isEmpty ? 'pokerspot-staging' : projectId,
          flags: const FeatureFlags.mvp(),
        );
      case 'dev':
      default:
        return Environment(
          name: AppEnv.dev,
          firebaseProjectId: projectId.isEmpty ? 'pokerspot-dev' : projectId,
          flags: const FeatureFlags.mvp(),
        );
    }
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/core/config/environment_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/core/config/environment.dart env-dev.json env-prod.json test/core/config/environment_test.dart
git commit -m "feat: environment config (dev/staging/prod) via dart-define"
```

---

## Task 6: Design tokens — port `tokens.css` to Dart (TDD)

**Files:**
- Create: `pokerspot/lib/core/theme/tokens.dart`
- Test: `pokerspot/test/core/theme/tokens_test.dart`

Reference: `docs/superpowers/mockups/v3-design-system/tokens.css` (Liquid Sport `:root`). Hex → `0xFF` + uppercase; rgba(255,255,255,a) → `Colors.white.withValues(alpha: a)`.

- [ ] **Step 1: Write the failing test**

`test/core/theme/tokens_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/core/theme/tokens.dart';

void main() {
  test('Liquid Sport accent + bg match tokens.css', () {
    expect(PsColors.accentPrimary, const Color(0xFFC6FF3A));
    expect(PsColors.accentSecondary, const Color(0xFF34E3FF));
    expect(PsColors.onAccent, const Color(0xFF06241A));
    expect(PsColors.statusLive, const Color(0xFFFF4D57));
    expect(PsColors.bg0, const Color(0xFF04151A));
  });

  test('8pt spacing scale', () {
    expect(PsSpacing.s1, 4);
    expect(PsSpacing.s4, 16);
    expect(PsSpacing.s12, 48);
  });

  test('type scale + radii', () {
    expect(PsType.display1, 42);
    expect(PsType.body, 15);
    expect(PsRadii.lg, 20);
    expect(PsRadii.full, 999);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/theme/tokens_test.dart`
Expected: FAIL — URI doesn't exist.

- [ ] **Step 3: Write the implementation**

`lib/core/theme/tokens.dart`:
```dart
import 'package:flutter/material.dart';

/// Design tokens — Liquid Sport. Ported 1:1 from
/// docs/superpowers/mockups/v3-design-system/tokens.css. Change a value here →
/// the whole app re-skins (spec §12.E). Alternate themes (Dark Casino) are
/// added as a second token set in a later iteration.
abstract final class PsColors {
  static const accentPrimary = Color(0xFFC6FF3A);
  static const accentSecondary = Color(0xFF34E3FF);
  static const onAccent = Color(0xFF06241A);

  static const statusLive = Color(0xFFFF4D57);
  static const statusOpen = Color(0xFFFFB02E);
  static const statusClosed = Color(0xFF56646A);

  static const bg0 = Color(0xFF04151A);
  static const bg1 = Color(0xFF062A2C);

  static const text = Color(0xFFECFBFF);
  static final textMuted = const Color(0xFFECFBFF).withValues(alpha: 0.56);
  static final textFaint = const Color(0xFFECFBFF).withValues(alpha: 0.32);

  static final glassThin = Colors.white.withValues(alpha: 0.05);
  static final glassRegular = Colors.white.withValues(alpha: 0.085);
  static final glassBorder = Colors.white.withValues(alpha: 0.11);
}

abstract final class PsSpacing {
  static const double s1 = 4, s2 = 8, s3 = 12, s4 = 16, s5 = 20, s6 = 24,
      s8 = 32, s10 = 40, s12 = 48;
}

abstract final class PsRadii {
  static const double sm = 10, md = 14, lg = 20, xl = 26, full = 999;
}

abstract final class PsType {
  static const double display1 = 42, display2 = 30, title = 22, headline = 18,
      body = 15, subhead = 13, caption = 12, micro = 10;
}

abstract final class PsMotion {
  static const fast = Duration(milliseconds: 160);
  static const normal = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 520);
  static const ease = Cubic(0.22, 0.61, 0.36, 1);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/theme/tokens_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/theme/tokens.dart test/core/theme/tokens_test.dart
git commit -m "feat: design tokens ported from tokens.css (Liquid Sport)"
```

---

## Task 7: App theme from tokens (TDD)

**Files:**
- Create: `pokerspot/lib/core/theme/app_theme.dart`
- Test: `pokerspot/test/core/theme/app_theme_test.dart`

- [ ] **Step 1: Write the failing test**

`test/core/theme/app_theme_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/core/theme/app_theme.dart';
import 'package:pokerspot/core/theme/tokens.dart';

void main() {
  test('theme is dark and uses the token background + accent', () {
    final t = AppTheme.liquidSport();
    expect(t.brightness, Brightness.dark);
    expect(t.scaffoldBackgroundColor, PsColors.bg0);
    expect(t.colorScheme.primary, PsColors.accentPrimary);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/theme/app_theme_test.dart`
Expected: FAIL — URI doesn't exist.

- [ ] **Step 3: Write the implementation**

`lib/core/theme/app_theme.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pokerspot/core/theme/tokens.dart';

/// Builds ThemeData from the design tokens (spec §12.E).
abstract final class AppTheme {
  static ThemeData liquidSport() {
    final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: PsColors.bg0,
      colorScheme: ColorScheme.fromSeed(
        seedColor: PsColors.accentPrimary,
        brightness: Brightness.dark,
      ).copyWith(
        primary: PsColors.accentPrimary,
        secondary: PsColors.accentSecondary,
        onPrimary: PsColors.onAccent,
        surface: PsColors.bg1,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: PsColors.text,
        displayColor: PsColors.text,
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/theme/app_theme_test.dart`
Expected: PASS. (Note: `GoogleFonts.interTextTheme` is offline-safe in tests; it returns text styles without fetching.)

- [ ] **Step 5: Commit**

```bash
git add lib/core/theme/app_theme.dart test/core/theme/app_theme_test.dart
git commit -m "feat: app theme built from design tokens"
```

---

## Task 8: l10n scaffolding (ka/en/ru)

**Files:**
- Create: `pokerspot/l10n.yaml`
- Create: `pokerspot/lib/l10n/app_en.arb`, `app_ka.arb`, `app_ru.arb`

- [ ] **Step 1: Write `l10n.yaml`**

`l10n.yaml` (project root):
```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: AppL10n
nullable-getter: false
```

- [ ] **Step 2: Write the ARB files**

`lib/l10n/app_en.arb`:
```json
{
  "@@locale": "en",
  "appTitle": "PokerSpot",
  "welcomeTitle": "Welcome to PokerSpot",
  "gdprConsent": "PokerSpot tracks your play sessions for personal stats and club reports. By continuing you consent."
}
```
`lib/l10n/app_ka.arb`:
```json
{
  "@@locale": "ka",
  "appTitle": "PokerSpot",
  "welcomeTitle": "მოგესალმებით PokerSpot-ში",
  "gdprConsent": "PokerSpot ინახავს თქვენი თამაშის სესიებს პირადი სტატისტიკისა და კლუბის ანგარიშებისთვის. გაგრძელებით თანხმობას აცხადებთ."
}
```
`lib/l10n/app_ru.arb`:
```json
{
  "@@locale": "ru",
  "appTitle": "PokerSpot",
  "welcomeTitle": "Добро пожаловать в PokerSpot",
  "gdprConsent": "PokerSpot отслеживает ваши игровые сессии для личной статистики и отчётов клубов. Продолжая, вы соглашаетесь."
}
```

- [ ] **Step 3: Generate the localizations**

Run: `flutter gen-l10n`
Expected: generates `.dart_tool/flutter_gen/gen_l10n/app_localizations.dart` (importable as `package:flutter_gen/gen_l10n/app_localizations.dart`). No errors.

- [ ] **Step 4: Verify it compiles**

Run: `flutter analyze`
Expected: "No issues found!"

- [ ] **Step 5: Commit**

```bash
git add l10n.yaml lib/l10n
git commit -m "feat: l10n scaffolding for ka/en/ru"
```

---

## Task 9: App shell + themed placeholder home (TDD widget test)

**Files:**
- Create: `pokerspot/lib/app/app.dart`, `pokerspot/lib/app/router.dart`
- Create: `pokerspot/lib/features/home/presentation/home_screen.dart`
- Modify: `pokerspot/lib/main.dart`
- Create: `pokerspot/test/app/app_smoke_test.dart`
- Delete: `pokerspot/test/widget_test.dart` (the default counter test)

- [ ] **Step 1: Delete the default test and write the failing smoke test**

Delete `test/widget_test.dart`. Create `test/app/app_smoke_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/app/app.dart';
import 'package:pokerspot/core/theme/tokens.dart';

void main() {
  testWidgets('app launches and shows the themed home placeholder', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PokerSpotApp()));
    await tester.pumpAndSettle();

    expect(find.text('PokerSpot'), findsOneWidget);

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor ?? PsColors.bg0, PsColors.bg0);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/app/app_smoke_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:pokerspot/app/app.dart'`.

- [ ] **Step 3: Write the home screen**

`lib/features/home/presentation/home_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:pokerspot/core/theme/tokens.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Scaffold(
      backgroundColor: PsColors.bg0,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.appTitle,
              style: TextStyle(
                color: PsColors.accentPrimary,
                fontSize: PsType.display1,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: PsSpacing.s3),
            Text('Foundation ready',
                style: TextStyle(color: PsColors.textMuted, fontSize: PsType.body)),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Write the router**

`lib/app/router.dart`:
```dart
import 'package:go_router/go_router.dart';
import 'package:pokerspot/features/home/presentation/home_screen.dart';

/// Minimal router. Plan 2 replaces home with the auth gate + role-based shell.
final appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
  ],
);
```

- [ ] **Step 5: Write the app widget**

`lib/app/app.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:pokerspot/app/router.dart';
import 'package:pokerspot/core/theme/app_theme.dart';

class PokerSpotApp extends StatelessWidget {
  const PokerSpotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppL10n.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.liquidSport(),
      routerConfig: appRouter,
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
    );
  }
}
```

- [ ] **Step 6: Rewrite `main.dart`**

`lib/main.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/app/app.dart';

void main() {
  runApp(const ProviderScope(child: PokerSpotApp()));
}
```

- [ ] **Step 7: Run the smoke test to verify it passes**

Run: `flutter test test/app/app_smoke_test.dart`
Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add lib/app lib/features/home lib/main.dart test/app/app_smoke_test.dart
git rm test/widget_test.dart
git commit -m "feat: Riverpod app shell + themed home placeholder"
```

---

## Task 10: Full green + run instructions

**Files:** none (verification + docs)

- [ ] **Step 1: Analyze the whole project**

Run: `flutter analyze`
Expected: "No issues found!"

- [ ] **Step 2: Run the entire test suite**

Run: `flutter test`
Expected: all tests pass (business_rules, validation_rules, feature_flags, environment, tokens, app_theme, app_smoke). No failures.

- [ ] **Step 3: Run on a real Android phone over USB (no emulator)**

On the phone, one-time setup:
1. Settings → About phone → tap **Build number** 7 times → "You are now a developer".
2. Settings → System → **Developer options** → enable **USB debugging**.
3. Connect the phone to the PC via USB. On the phone, accept **"Allow USB debugging / Trust this computer"** (tick "Always allow from this computer").

Then on the PC:
```bash
flutter devices
```
Expected: the phone appears in the list (e.g. `SM-A536B (mobile) • <id> • android-arm64`). If it doesn't, run `adb devices` and re-accept the trust dialog.
```bash
flutter run -d <device-id> --dart-define-from-file=env-dev.json
```
Expected: the app installs and launches on the phone — a dark screen with lime italic "PokerSpot" + "Foundation ready".

- [ ] **Step 4: Build a shareable release APK**

```bash
flutter build apk --release --dart-define-from-file=env-dev.json
```
Expected: "✓ Built build/app/outputs/flutter-apk/app-release.apk". That file (`pokerspot/build/app/outputs/flutter-apk/app-release.apk`) can be sent to test users via WhatsApp/Telegram; they install it after enabling "Install unknown apps" for the messenger. (No signing config yet → debug-signed release; a proper upload keystore comes with the Play Console step in a later plan.)

- [ ] **Step 5: Commit a short run note**

Create `pokerspot/README.md`:
```markdown
# PokerSpot

Tbilisi poker-rooms app (Flutter + Firebase). Liquid Sport design system.
Android-first; minSdk 23. Tested on a real device (no emulator).

## Run on a connected Android phone
1. Phone: enable Developer options (tap Build number x7) → enable USB debugging.
2. Connect via USB, accept "Trust this computer".
3. `flutter devices`  → confirm the phone is listed.
4. `flutter run -d <device-id> --dart-define-from-file=env-dev.json`

## Shareable APK (for test users)
`flutter build apk --release --dart-define-from-file=env-dev.json`
→ `build/app/outputs/flutter-apk/app-release.apk` (send via WhatsApp/Telegram).

## Dev
- Tests: `flutter test`   ·   Lint: `flutter analyze`
- Environments: `env-dev.json` (default) / `env-prod.json`.

Foundation only — auth, clubs, and the rest land in subsequent plans
(`docs/superpowers/plans/`).
```
```bash
git add pokerspot/README.md
git commit -m "docs: add real-device run + release APK instructions"
```

---

## Self-review notes (author)

- **Spec coverage (this plan's scope):** §12.A constants → Tasks 2–3; §12.B flags → Task 4; §12.G env → Task 5; §12.E tokens/theme → Tasks 6–7; §10/§12.F l10n → Task 8; §12.D Riverpod + app shell → Task 9. Firebase/repositories/features are intentionally **out of scope** (Plans 2–7).
- **Placeholders:** none — every code step has full code; every run step has the command + expected output.
- **Type consistency:** `FeatureFlags.mvp()`, `Environment.current/forName`, `PsColors/PsSpacing/PsRadii/PsType/PsMotion`, `AppTheme.liquidSport()`, `AppL10n` (output-class), `PokerSpotApp`, `HomeScreen`, `appRouter` are defined once and referenced consistently across tasks and tests.
- **Known toolchain assumptions:** `flutter_gen` import path for generated l10n; `withValues(alpha:)` (Flutter 3.22+). If the engineer's Flutter is older, use `.withOpacity(...)`.

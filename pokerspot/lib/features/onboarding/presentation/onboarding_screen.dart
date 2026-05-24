import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/core/constants/validation_rules.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';
import 'package:pokerspot/shared/widgets/centered_pane.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  String _lang = 'en';
  bool _busy = false;

  bool get _canSubmit =>
      ValidationRules.isValidFirstName(_first.text) &&
      ValidationRules.isValidLastName(_last.text) &&
      ValidationRules.firstAndLastNamesDiffer(_first.text, _last.text);

  /// Inline error for the first-name field (only once the user has typed).
  String? _firstError(AppL10n l10n) {
    if (_first.text.trim().isEmpty) return null;
    return ValidationRules.isValidFirstName(_first.text) ? null : l10n.nameTooShort;
  }

  /// Inline error for the last-name field: too-short takes precedence; once both
  /// names are valid, surface the "must differ" message here.
  String? _lastError(AppL10n l10n) {
    if (_last.text.trim().isEmpty) return null;
    if (!ValidationRules.isValidLastName(_last.text)) return l10n.nameTooShort;
    if (ValidationRules.isValidFirstName(_first.text) &&
        !ValidationRules.firstAndLastNamesDiffer(_first.text, _last.text)) {
      return l10n.namesMustDiffer;
    }
    return null;
  }

  Future<void> _submit() async {
    final uid = ref.read(authRepositoryProvider).currentUid;
    if (uid == null || !_canSubmit) return;
    setState(() => _busy = true);
    await ref.read(usersRepositoryProvider).createProfile(
          uid: uid,
          // Backfill the real auth phone (Plan 7 work pulled forward so the
          // setup_test_users tool can match users by phone).
          phone: ref.read(authRepositoryProvider).currentPhone ?? '',
          firstName: _first.text.trim(),
          lastName: _last.text.trim(),
          lang: _lang,
        );
    // currentUserProvider will emit the new profile → router redirects to /home.
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Scaffold(
      backgroundColor: PsColors.bg0,
      body: CenteredPane(
        child: Padding(
          padding: const EdgeInsets.all(PsSpacing.s5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.welcomeTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: PsColors.text, fontSize: PsType.title, fontWeight: FontWeight.w900)),
              const SizedBox(height: PsSpacing.s6),
              TextField(
                key: const Key('firstNameField'),
                controller: _first,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                    labelText: l10n.firstName,
                    hintText: l10n.firstNameHint,
                    errorText: _firstError(l10n)),
              ),
              const SizedBox(height: PsSpacing.s4),
              TextField(
                key: const Key('lastNameField'),
                controller: _last,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                    labelText: l10n.lastName,
                    hintText: l10n.lastNameHint,
                    errorText: _lastError(l10n)),
              ),
              const SizedBox(height: PsSpacing.s4),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'ka', label: Text('ქა')),
                  ButtonSegment(value: 'en', label: Text('EN')),
                  ButtonSegment(value: 'ru', label: Text('РУ')),
                ],
                selected: {_lang},
                onSelectionChanged: (s) => setState(() => _lang = s.first),
              ),
              const SizedBox(height: PsSpacing.s6),
              FilledButton(
                key: const Key('getStartedBtn'),
                onPressed: (_canSubmit && !_busy) ? _submit : null,
                child: Text(l10n.getStarted),
              ),
              const SizedBox(height: PsSpacing.s3),
              Text(l10n.gdprConsent,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: PsColors.textFaint, fontSize: PsType.caption)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    super.dispose();
  }
}

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
  final _name = TextEditingController();
  String _lang = 'en';
  bool _busy = false;

  bool get _valid => ValidationRules.isValidName(_name.text);

  Future<void> _submit() async {
    final uid = ref.read(authRepositoryProvider).currentUid;
    if (uid == null || !_valid) return;
    setState(() => _busy = true);
    await ref.read(usersRepositoryProvider).createProfile(
          uid: uid,
          phone: '', // backfilled from auth in Plan 7; not needed for routing
          displayName: _name.text.trim(),
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
                key: const Key('nameField'),
                controller: _name,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(labelText: l10n.yourName, hintText: l10n.nameHint),
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
                onPressed: (_valid && !_busy) ? _submit : null,
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
    _name.dispose();
    super.dispose();
  }
}

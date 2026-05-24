import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/core/constants/validation_rules.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';
import 'package:pokerspot/shared/widgets/centered_pane.dart';
import 'package:pokerspot/shared/widgets/ps_button.dart';
import 'package:pokerspot/shared/widgets/ps_scaffold.dart';
import 'package:pokerspot/shared/widgets/ps_text_field.dart';

/// (code, label, endonym) for the language picker. Endonyms are intentionally
/// shown in each language's own script regardless of the app locale.
const _languages = <(String, String, String)>[
  ('ka', 'ქა', 'ქართული'),
  ('en', 'EN', 'English'),
  ('ru', 'РУ', 'Русский'),
];

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

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: PsSpacing.s2),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: PsType.caption,
            fontWeight: PsType.weightBlack,
            letterSpacing: PsType.trackingWide,
            color: PsColors.textFaint,
          ),
        ),
      );

  /// "Welcome to PokerSpot" with the brand word accented.
  Widget _title(AppL10n l10n) {
    const base = TextStyle(
      fontSize: PsType.display2,
      fontWeight: PsType.weightBlack,
      height: 1.05,
      letterSpacing: PsType.trackingTight,
      color: PsColors.text,
    );
    final title = l10n.welcomeTitle;
    final brand = l10n.appTitle;
    final i = title.indexOf(brand);
    if (i < 0) return Text(title, style: base);
    return Text.rich(
      TextSpan(style: base, children: [
        if (i > 0) TextSpan(text: title.substring(0, i)),
        TextSpan(text: brand, style: base.copyWith(color: PsColors.accentPrimary)),
        if (i + brand.length < title.length) TextSpan(text: title.substring(i + brand.length)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return PsScaffold(
      body: CenteredPane(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(PsSpacing.s5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: PsSpacing.s8),
              const _HeroOrb(),
              const SizedBox(height: PsSpacing.s5),
              _title(l10n),
              const SizedBox(height: PsSpacing.s3),
              Text(
                l10n.welcomeSub,
                style: TextStyle(
                  fontSize: PsType.headline,
                  fontWeight: PsType.weightMedium,
                  height: 1.4,
                  color: PsColors.textMuted,
                ),
              ),
              const SizedBox(height: PsSpacing.s6),
              _fieldLabel(l10n.firstName),
              PsTextField(
                key: const Key('firstNameField'),
                controller: _first,
                hintText: l10n.firstNameHint,
                errorText: _firstError(l10n),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: PsSpacing.s4),
              _fieldLabel(l10n.lastName),
              PsTextField(
                key: const Key('lastNameField'),
                controller: _last,
                hintText: l10n.lastNameHint,
                errorText: _lastError(l10n),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: PsSpacing.s5),
              _fieldLabel(l10n.language),
              Row(
                children: [
                  for (var i = 0; i < _languages.length; i++) ...[
                    if (i > 0) const SizedBox(width: PsSpacing.s2),
                    Expanded(
                      child: _LangOption(
                        code: _languages[i].$2,
                        name: _languages[i].$3,
                        selected: _lang == _languages[i].$1,
                        onTap: () => setState(() => _lang = _languages[i].$1),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: PsSpacing.s6),
              SizedBox(
                width: double.infinity,
                child: PsButton(
                  key: const Key('getStartedBtn'),
                  label: l10n.getStarted,
                  onPressed: (_canSubmit && !_busy) ? _submit : null,
                ),
              ),
              const SizedBox(height: PsSpacing.s3),
              Text(
                l10n.gdprConsent,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: PsType.caption,
                  height: 1.4,
                  color: PsColors.textFaint,
                ),
              ),
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

/// The 84px gradient hero orb with the spade glyph (mockup `.hero-orb`).
class _HeroOrb extends StatelessWidget {
  const _HeroOrb();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(PsRadii.xl),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [PsColors.accentPrimary, PsColors.accentSecondary],
        ),
        boxShadow: [
          ...PsElevation.e3,
          const BoxShadow(color: PsColors.accentPrimary, blurRadius: 40, spreadRadius: -6),
        ],
      ),
      child: const Text(
        '♠',
        style: TextStyle(fontSize: 44, fontWeight: PsType.weightBlack, color: PsColors.onAccent),
      ),
    );
  }
}

/// One language tile in the picker (mockup `.lang-opt`).
class _LangOption extends StatefulWidget {
  const _LangOption({
    required this.code,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final String code;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_LangOption> createState() => _LangOptionState();
}

class _LangOptionState extends State<_LangOption> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final sel = widget.selected;
    final fg = sel ? PsColors.accentPrimary : PsColors.text;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: PsMotion.fast,
        curve: PsMotion.ease,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          decoration: BoxDecoration(
            color: sel ? PsColors.accentPrimary.withValues(alpha: 0.12) : PsColors.glassThin,
            borderRadius: BorderRadius.circular(PsRadii.md),
            border: Border.all(color: sel ? PsColors.accentPrimary : PsColors.glassBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.code,
                style: TextStyle(fontSize: PsType.body, fontWeight: PsType.weightBold, color: fg),
              ),
              const SizedBox(height: 2),
              Text(
                widget.name,
                style: TextStyle(
                  fontSize: PsType.micro,
                  fontWeight: PsType.weightMedium,
                  color: sel ? PsColors.accentPrimary : PsColors.textFaint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

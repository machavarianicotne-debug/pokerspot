import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/core/constants/validation_rules.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/features/auth/domain/auth_repository.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';
import 'package:pokerspot/shared/widgets/centered_pane.dart';
import 'package:pokerspot/shared/widgets/ps_brand.dart';
import 'package:pokerspot/shared/widgets/ps_button.dart';
import 'package:pokerspot/shared/widgets/ps_scaffold.dart';
import 'package:pokerspot/shared/widgets/ps_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  OtpSession? _session;
  String? _error;
  bool _busy = false;

  /// Build the E.164 number from local input — the user types only their local
  /// Georgian number (no +995); we prepend it. Tolerates a pasted +995 / 995 /
  /// leading 0.
  static String _toE164(String raw) {
    var d = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (d.startsWith('995')) d = d.substring(3);
    if (d.startsWith('0')) d = d.substring(1);
    return '+995$d';
  }

  Future<void> _send() async {
    setState(() => _error = null);
    final e164 = _toE164(_phone.text);
    if (!ValidationRules.isValidPhone(e164)) {
      setState(() => _error = AppL10n.of(context).invalidPhone);
      return;
    }
    setState(() => _busy = true);
    try {
      _session = await ref.read(authRepositoryProvider).sendOtp(e164);
    } on AuthException catch (e) {
      _error = e.message;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      await ref.read(authRepositoryProvider).confirmOtp(_session!, _code.text.trim());
    } on AuthException catch (e) {
      _error = e.message;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final sent = _session != null;
    return PsScaffold(
      body: CenteredPane(
        child: Padding(
          padding: const EdgeInsets.all(PsSpacing.s5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: PsBrand(l10n.appTitle, accent: 'Spot', fontSize: PsType.display1)),
              const SizedBox(height: PsSpacing.s8),
              if (!sent) ...[
                Row(
                  children: [
                    // Fixed Georgia country code — the user types only the local
                    // number; +995 is added automatically.
                    Container(
                      height: 52,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: PsSpacing.s4),
                      margin: const EdgeInsets.only(right: PsSpacing.s2),
                      decoration: BoxDecoration(
                        color: PsColors.glassRegular,
                        borderRadius: BorderRadius.circular(PsRadii.md),
                        border: Border.all(color: PsColors.glassBorder),
                      ),
                      child: const Text('🇬🇪 +995',
                          style: TextStyle(
                              fontSize: PsType.body,
                              fontWeight: PsType.weightBold,
                              color: PsColors.text)),
                    ),
                    Expanded(
                      child: PsTextField(
                        key: const Key('phoneField'),
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        hintText: l10n.phoneHint,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) {
                          if (!_busy) _send();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: PsSpacing.s4),
                PsButton(
                  key: const Key('sendCodeBtn'),
                  label: l10n.sendCode,
                  onPressed: _busy ? null : _send,
                ),
              ] else ...[
                PsTextField(
                  key: const Key('codeField'),
                  controller: _code,
                  keyboardType: TextInputType.number,
                  hintText: l10n.smsHint,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    if (!_busy) _verify();
                  },
                ),
                const SizedBox(height: PsSpacing.s4),
                PsButton(
                  key: const Key('verifyBtn'),
                  label: l10n.verify,
                  onPressed: _busy ? null : _verify,
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: PsSpacing.s3),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: PsColors.statusLive,
                    fontSize: PsType.subhead,
                    fontWeight: PsType.weightMedium,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }
}

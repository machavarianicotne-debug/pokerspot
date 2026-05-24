import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/core/constants/validation_rules.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/features/auth/domain/auth_repository.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';
import 'package:pokerspot/shared/widgets/centered_pane.dart';

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

  Future<void> _send() async {
    setState(() => _error = null);
    if (!ValidationRules.isValidPhone(_phone.text)) {
      setState(() => _error = AppL10n.of(context).invalidPhone);
      return;
    }
    setState(() => _busy = true);
    try {
      _session = await ref.read(authRepositoryProvider).sendOtp(_phone.text);
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
    return Scaffold(
      backgroundColor: PsColors.bg0,
      body: CenteredPane(
        child: Padding(
          padding: const EdgeInsets.all(PsSpacing.s5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.appTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: PsColors.accentPrimary,
                      fontSize: PsType.display1,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic)),
              const SizedBox(height: PsSpacing.s8),
              if (!sent) ...[
                TextField(
                  key: const Key('phoneField'),
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                      labelText: l10n.phoneNumber, hintText: l10n.phoneHint),
                ),
                const SizedBox(height: PsSpacing.s4),
                FilledButton(
                  key: const Key('sendCodeBtn'),
                  onPressed: _busy ? null : _send,
                  child: Text(l10n.sendCode),
                ),
              ] else ...[
                TextField(
                  key: const Key('codeField'),
                  controller: _code,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      labelText: l10n.smsCode, hintText: l10n.smsHint),
                ),
                const SizedBox(height: PsSpacing.s4),
                FilledButton(
                  key: const Key('verifyBtn'),
                  onPressed: _busy ? null : _verify,
                  child: Text(l10n.verify),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: PsSpacing.s3),
                Text(_error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: PsColors.statusLive)),
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

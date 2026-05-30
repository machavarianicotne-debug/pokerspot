import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/app/router.dart';
import 'package:pokerspot/core/push/push_service.dart';
import 'package:pokerspot/core/theme/app_theme.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';

class PokerSpotApp extends ConsumerStatefulWidget {
  const PokerSpotApp({super.key});

  @override
  ConsumerState<PokerSpotApp> createState() => _PokerSpotAppState();
}

class _PokerSpotAppState extends ConsumerState<PokerSpotApp> {
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  StreamSubscription<RemoteMessage>? _fgSub;

  @override
  void initState() {
    super.initState();
    // A push that arrives while the app is open (foreground) won't show an OS
    // notification — surface it ourselves as a top heads-up banner + haptic +
    // sound, so the player notices on whatever screen they're on.
    _fgSub = FirebaseMessaging.onMessage.listen((m) {
      final n = m.notification;
      if (n != null) _showInAppBanner(n.title ?? '', n.body ?? '');
    });
    // Pre-register for APNs early (iOS) so Firebase phone-auth verification has a
    // device token BEFORE the user taps "send code". Without an APNs token the
    // SDK falls back to reCAPTCHA, which has no clientID here and hard-crashes
    // (EXC_BREAKPOINT in PhoneAuthProvider.verifyPhoneNumber).
    if (!kIsWeb) unawaited(_warmUpApns());
  }

  Future<void> _warmUpApns() async {
    try {
      await FirebaseMessaging.instance.requestPermission();
      await FirebaseMessaging.instance.getAPNSToken();
    } catch (_) {
      // Best-effort: phone-auth still attempts its own APNs registration.
    }
  }

  @override
  void dispose() {
    _fgSub?.cancel();
    super.dispose();
  }

  void _showInAppBanner(String title, String body) {
    final messenger = _messengerKey.currentState;
    if (messenger == null) return;
    HapticFeedback.heavyImpact(); // vibration (native; no-op on web)
    SystemSound.play(SystemSoundType.alert); // sound (system)
    messenger.clearMaterialBanners();
    messenger.showMaterialBanner(MaterialBanner(
      backgroundColor: PsColors.glassThick,
      leading: const Icon(Icons.notifications_active, color: PsColors.accentPrimary),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Text(title,
                style: const TextStyle(
                    fontSize: PsType.body, fontWeight: PsType.weightBlack, color: PsColors.text)),
          if (body.isNotEmpty)
            Text(body, style: TextStyle(fontSize: PsType.subhead, color: PsColors.textMuted)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => messenger.hideCurrentMaterialBanner(),
          child: const Text('OK', style: TextStyle(color: PsColors.accentPrimary)),
        ),
      ],
    ));
    // Auto-dismiss after a few seconds (like a heads-up notification).
    Timer(const Duration(seconds: 4), () => _messengerKey.currentState?.hideCurrentMaterialBanner());
  }

  @override
  Widget build(BuildContext context) {
    // Register the Web Push token once the user is signed in (best-effort).
    ref.listen(uidProvider, (prev, next) {
      final uid = next.valueOrNull;
      if (uid != null) {
        unawaited(registerPush(uid, ref.read(usersRepositoryProvider)));
      }
    });
    return MaterialApp.router(
      scaffoldMessengerKey: _messengerKey,
      onGenerateTitle: (context) => AppL10n.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      // The mockups (web) are the source of truth and use a fixed 1.0 text
      // scale. iOS otherwise applies the device "Text Size" setting, blowing up
      // fonts (and text-driven sizes like tab labels) past the design. Pin it.
      builder: (context, child) => MediaQuery.withNoTextScaling(child: child!),
      theme: AppTheme.liquidSport(),
      routerConfig: ref.watch(routerProvider),
      // Drive the UI language from the signed-in user's saved `lang` (null falls
      // back to the device locale) so the settings language picker takes effect.
      locale: ref.watch(localeProvider),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
    );
  }
}

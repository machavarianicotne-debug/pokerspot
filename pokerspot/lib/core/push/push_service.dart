import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:pokerspot/features/auth/domain/users_repository.dart';

/// Web Push (VAPID) public key for this project — generated in the Firebase
/// console (Cloud Messaging → Web Push certificates). Public by design.
const _vapidKey =
    'BBlWUJMjsb84a7yDG_bUH8OuXG7BWQQv6ku3VES0WfN2PNXn4LBXGz6od0xv4dlXMHTIpcKnmWpW5FGD9queHLo';

/// Requests notification permission and registers the device's FCM token for
/// [uid] (saved to `users/{uid}.fcmTokens`, which the notifyCalled Cloud
/// Function reads to push "you're called" / chat alerts). Best-effort: a denied
/// permission, private window, or unsupported browser is silently ignored.
Future<void> registerPush(String uid, UsersRepository users) async {
  try {
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;
    // iOS: getToken() throws "apns-token-not-set" if the APNs token hasn't
    // arrived yet (it's delivered async after registerForRemoteNotifications).
    // Without this wait the call throws, is swallowed below, and the device
    // never registers — so no push ever lands. Poll up to ~10s for the token.
    if (!kIsWeb) {
      var apns = await messaging.getAPNSToken();
      for (var i = 0; apns == null && i < 10; i++) {
        await Future<void>.delayed(const Duration(seconds: 1));
        apns = await messaging.getAPNSToken();
      }
      if (apns == null) return; // no APNs (e.g. simulator) — can't get a token
    }
    final token =
        kIsWeb ? await messaging.getToken(vapidKey: _vapidKey) : await messaging.getToken();
    if (token == null || token.isEmpty) return;
    await users.addFcmToken(uid, token);
    messaging.onTokenRefresh.listen((t) => users.addFcmToken(uid, t));
  } catch (_) {
    // Push is best-effort — ignore failures so they never block sign-in.
  }
}

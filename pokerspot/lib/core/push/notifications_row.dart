import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pokerspot/core/push/push_service.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/shared/widgets/ps_settings_group.dart';
import 'package:pokerspot/shared/widgets/ps_toggle.dart';

/// Settings row that reflects and controls the OS notification permission.
///
/// - OFF→ON the first time (notDetermined): shows the system permission dialog,
///   then registers the FCM token so pushes start arriving.
/// - Once the permission is already decided (granted or denied), iOS won't
///   re-show the dialog, so tapping deep-links to the system Settings page for
///   this app where the user can flip it.
///
/// The shown value always mirrors the real OS permission (re-read on mount and
/// after every tap), so it can't drift out of sync with what the system grants.
class PsNotificationsRow extends ConsumerStatefulWidget {
  const PsNotificationsRow({super.key, required this.uid});

  final String uid;

  @override
  ConsumerState<PsNotificationsRow> createState() => _PsNotificationsRowState();
}

class _PsNotificationsRowState extends ConsumerState<PsNotificationsRow> {
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  bool _granted(AuthorizationStatus s) =>
      s == AuthorizationStatus.authorized || s == AuthorizationStatus.provisional;

  Future<void> _refresh() async {
    try {
      final s = await FirebaseMessaging.instance.getNotificationSettings();
      if (mounted) setState(() => _enabled = _granted(s.authorizationStatus));
    } catch (_) {
      // Messaging unavailable (e.g. unsupported browser) — leave the row OFF.
    }
  }

  Future<void> _onTap(bool want) async {
    try {
      final messaging = FirebaseMessaging.instance;
      final status = (await messaging.getNotificationSettings()).authorizationStatus;
      if (want && status == AuthorizationStatus.notDetermined) {
        // First decision — show the OS dialog, then register the token.
        final res = await messaging.requestPermission();
        if (_granted(res.authorizationStatus)) {
          await registerPush(widget.uid, ref.read(usersRepositoryProvider));
        }
      } else {
        // Already decided — the OS dialog won't re-appear, so send the user to
        // the system Settings for this app to grant/revoke it there.
        await _openSystemSettings();
      }
    } catch (_) {
      // best-effort
    }
    await _refresh();
  }

  Future<void> _openSystemSettings() async {
    if (kIsWeb) return;
    final uri = Uri.parse('app-settings:'); // iOS: this app's Settings page.
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return PsSettingsRow(
      label: AppL10n.of(context).allowNotifications,
      trailing: PsToggle(value: _enabled, onChanged: _onTap),
    );
  }
}

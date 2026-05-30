import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/core/push/notifications_row.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';
import 'package:pokerspot/shared/widgets/ps_avatar.dart';
import 'package:pokerspot/shared/widgets/ps_button.dart';
import 'package:pokerspot/shared/widgets/ps_settings_group.dart';
import 'package:pokerspot/shared/widgets/ps_sheet.dart';
import 'package:pokerspot/shared/widgets/ps_toggle.dart';

const _langNames = <String, String>{'en': 'English', 'ka': 'ქართული', 'ru': 'Русский'};

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    final p = parts.first;
    return (p.length >= 2 ? p.substring(0, 2) : p).toUpperCase();
  }
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

/// The Profile tab, shared by all three roles: header (avatar/name/phone), an
/// Account group, Notifications toggles, and sign-out. Notification prefs are
/// local UI state for now (no `users.notif` persistence yet — deferred per spec).
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _seatCalled = true;
  bool _reservation = true;
  bool _clubNews = false;

  /// Pick the UI language; persists to the user doc so the whole app re-renders
  /// (MaterialApp.locale is bound to the saved lang via localeProvider).
  void _pickLanguage(String uid, String current) {
    PsSheet.show<void>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(AppL10n.of(context).language,
              style: const TextStyle(
                  fontSize: PsType.headline, fontWeight: PsType.weightBold, color: PsColors.text)),
          const SizedBox(height: PsSpacing.s3),
          PsSettingsGroup(children: [
            for (final e in _langNames.entries)
              PsSettingsRow(
                label: e.value,
                trailing: e.key == current
                    ? const Icon(Icons.check, size: 18, color: PsColors.accentPrimary)
                    : null,
                onTap: () {
                  final nav = Navigator.of(context);
                  unawaited(ref.read(usersRepositoryProvider).setLang(uid, e.key));
                  nav.pop();
                },
              ),
          ]),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final user = ref.watch(currentUserProvider).valueOrNull;
    if (user == null) {
      return const Center(child: CircularProgressIndicator(color: PsColors.accentPrimary));
    }
    final name = '${user.firstName} ${user.lastName}'.trim();
    final langLabel = _langNames[user.lang] ?? user.lang;

    return ListView(
      padding: const EdgeInsets.fromLTRB(PsSpacing.s4, PsSpacing.s4, PsSpacing.s4, 96),
      children: [
        Row(
          children: [
            PsAvatar(initials: _initials(name.isEmpty ? '?' : name), size: 64),
            const SizedBox(width: PsSpacing.s4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name.isEmpty ? l10n.tabProfile : name,
                      style: const TextStyle(
                          fontSize: PsType.title,
                          fontWeight: PsType.weightBlack,
                          letterSpacing: PsType.trackingSnug,
                          color: PsColors.text)),
                  if (user.phone.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(user.phone,
                        style: TextStyle(fontSize: PsType.body, color: PsColors.textMuted)),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: PsSpacing.s6),
        PsSettingsGroup.header(l10n.accountHeader),
        PsSettingsGroup(children: [
          PsSettingsRow(label: l10n.phoneNumber, value: user.phone),
          PsSettingsRow(
            label: l10n.language,
            value: langLabel,
            onTap: () => _pickLanguage(user.uid, user.lang),
          ),
        ]),
        const SizedBox(height: PsSpacing.s5),
        PsSettingsGroup.header(l10n.notificationsHeader),
        PsSettingsGroup(children: [
          PsNotificationsRow(uid: user.uid),
          PsSettingsRow(
            label: l10n.notifSeatCalled,
            trailing: PsToggle(value: _seatCalled, onChanged: (v) => setState(() => _seatCalled = v)),
          ),
          PsSettingsRow(
            label: l10n.notifReservation,
            trailing: PsToggle(value: _reservation, onChanged: (v) => setState(() => _reservation = v)),
          ),
          PsSettingsRow(
            label: l10n.notifClubNews,
            trailing: PsToggle(value: _clubNews, onChanged: (v) => setState(() => _clubNews = v)),
          ),
        ]),
        const SizedBox(height: PsSpacing.s6),
        PsButton(
          key: const Key('signOutBtn'),
          label: l10n.signOut,
          icon: Icons.logout,
          variant: PsButtonVariant.secondary,
          onPressed: () => ref.read(authRepositoryProvider).signOut(),
        ),
        const SizedBox(height: PsSpacing.s2),
        PsButton(
          key: const Key('deleteAccountBtn'),
          label: l10n.deleteAccount,
          icon: Icons.delete_outline,
          variant: PsButtonVariant.secondary,
          onPressed: () => unawaited(_deleteAccount(user.uid)),
        ),
      ],
    );
  }

  /// Request permanent account deletion (App Store / GDPR right-to-erasure) after
  /// a confirm dialog: writes the deletion request (a Cloud Function cascades the
  /// data + Auth account), then signs out.
  Future<void> _deleteAccount(String uid) async {
    final l10n = AppL10n.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAccount),
        content: Text(l10n.deleteAccountConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.cancelWaitlist)),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(l10n.deleteAccount)),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(usersRepositoryProvider).requestAccountDeletion(uid);
    await ref.read(authRepositoryProvider).signOut();
  }
}

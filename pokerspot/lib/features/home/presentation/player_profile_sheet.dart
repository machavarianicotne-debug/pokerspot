import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/features/auth/domain/app_user.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';
import 'package:pokerspot/shared/widgets/ps_avatar.dart';
import 'package:pokerspot/shared/widgets/ps_sheet.dart';

/// A bottom sheet showing a player's profile (name + phone) — opened by staff
/// (Pit Boss / Admin) from the Stats leaderboard and chat. Resolves the user
/// from [allUsersProvider] (Pit Bosses may read users); walk-ins have no profile.
class PlayerProfileSheet extends ConsumerWidget {
  const PlayerProfileSheet({super.key, required this.uid, this.fallbackName = ''});

  final String uid;
  final String fallbackName;

  /// Convenience opener.
  static void show(BuildContext context, {required String uid, String fallbackName = ''}) {
    unawaited(PsSheet.show<void>(
      context,
      child: PlayerProfileSheet(uid: uid, fallbackName: fallbackName),
    ));
  }

  String _initials(String s) {
    final parts = s.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return (parts.length == 1
            ? (parts.first.length >= 2 ? parts.first.substring(0, 2) : parts.first)
            : parts.first[0] + parts.last[0])
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final walkIn = uid.startsWith('walk-in:');
    final users = ref.watch(allUsersProvider).valueOrNull ?? const <AppUser>[];
    AppUser? user;
    for (final u in users) {
      if (u.uid == uid) {
        user = u;
        break;
      }
    }
    final name = user == null
        ? (fallbackName.isEmpty ? '—' : fallbackName)
        : '${user.firstName} ${user.lastName}'.trim();
    final phone = user?.phone ?? '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            PsAvatar(initials: _initials(name), size: 52),
            const SizedBox(width: PsSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: PsType.headline,
                          fontWeight: PsType.weightBlack,
                          color: PsColors.text)),
                  const SizedBox(height: 2),
                  Text(walkIn ? l10n.walkInLabel : l10n.registeredLabel,
                      style: TextStyle(
                          fontSize: PsType.caption,
                          fontWeight: PsType.weightBold,
                          color: walkIn ? PsColors.textFaint : PsColors.accentPrimary)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: PsSpacing.s4),
        if (phone.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: PsSpacing.s4, vertical: PsSpacing.s3),
            decoration: BoxDecoration(
              color: PsColors.glassThin,
              borderRadius: BorderRadius.circular(PsRadii.md),
              border: Border.all(color: PsColors.glassBorder),
            ),
            child: Row(
              children: [
                GestureDetector(
                  key: const Key('profilePhoneTile'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () =>
                      unawaited(launchUrl(Uri.parse('tel:${phone.replaceAll(RegExp(r'[^\d+]'), '')}'))),
                  child: Row(
                    children: [
                      const Icon(Icons.call, size: 18, color: PsColors.accentSecondary),
                      const SizedBox(width: PsSpacing.s3),
                      Text(phone,
                          style: const TextStyle(
                              fontSize: PsType.body,
                              fontWeight: PsType.weightBold,
                              color: PsColors.accentSecondary)),
                    ],
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  key: const Key('profileCopyPhone'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    unawaited(Clipboard.setData(ClipboardData(text: phone)));
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(l10n.phoneCopied)));
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(PsSpacing.s1),
                    child: Icon(Icons.copy, size: 18, color: PsColors.textMuted),
                  ),
                ),
              ],
            ),
          )
        else
          Text(walkIn ? l10n.walkInLabel : '—',
              style: TextStyle(fontSize: PsType.body, color: PsColors.textMuted)),
      ],
    );
  }
}

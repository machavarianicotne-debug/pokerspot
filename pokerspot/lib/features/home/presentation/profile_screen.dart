import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';
import 'package:pokerspot/shared/widgets/ps_avatar.dart';
import 'package:pokerspot/shared/widgets/ps_button.dart';
import 'package:pokerspot/shared/widgets/ps_card.dart';
import 'package:pokerspot/shared/widgets/ps_list_tile.dart';

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

/// The Profile tab, shared by all three role homes: the signed-in user's name,
/// phone and language, plus the sign-out action (moved here from the nav bars).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        PsCard(
          accentRail: PsColors.accentSecondary,
          child: Row(
            children: [
              PsAvatar(initials: _initials(name.isEmpty ? '?' : name), size: 56),
              const SizedBox(width: PsSpacing.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? l10n.tabProfile : name,
                      style: const TextStyle(
                        fontSize: PsType.title,
                        fontWeight: PsType.weightBlack,
                        letterSpacing: PsType.trackingSnug,
                        color: PsColors.text,
                      ),
                    ),
                    if (user.phone.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        user.phone,
                        style: TextStyle(
                          fontSize: PsType.subhead,
                          fontWeight: PsType.weightMedium,
                          color: PsColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: PsSpacing.s4),
        PsCard(
          child: PsListTile(
            title: l10n.language,
            trailing: Text(
              langLabel,
              style: const TextStyle(
                fontSize: PsType.body,
                fontWeight: PsType.weightBold,
                color: PsColors.accentPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(height: PsSpacing.s5),
        PsButton(
          key: const Key('signOutBtn'),
          label: l10n.signOut,
          icon: Icons.logout,
          variant: PsButtonVariant.secondary,
          onPressed: () => ref.read(authRepositoryProvider).signOut(),
        ),
      ],
    );
  }
}

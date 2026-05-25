import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/features/auth/domain/app_user.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';
import 'package:pokerspot/features/clubs/presentation/providers.dart';
import 'package:pokerspot/shared/widgets/ps_avatar.dart';
import 'package:pokerspot/shared/widgets/ps_button.dart';
import 'package:pokerspot/shared/widgets/ps_settings_group.dart';

/// Super Admin Settings tab (mockup `super-admin-settings`): app-wide defaults,
/// read-only feature flags and live system health. The defaults / flags reflect
/// the MVP reality (not yet editable); health is computed from the live data.
class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

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
    final user = ref.watch(currentUserProvider).valueOrNull;
    final name = user == null ? '' : '${user.firstName} ${user.lastName}'.trim();
    final clubs = ref.watch(allClubsProvider).valueOrNull ?? const [];
    final users = ref.watch(allUsersProvider).valueOrNull ?? const <AppUser>[];
    final activeClubs = clubs.where((c) => c.enabled).length;
    final players = users.where((u) => u.role == AppRole.player).length;
    final pitbosses = users.where((u) => u.role == AppRole.pitboss).length;
    final admins = users.where((u) => u.role == AppRole.superadmin).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(PsSpacing.s4, PsSpacing.s4, PsSpacing.s4, 96),
      children: [
        Row(
          children: [
            PsAvatar(initials: _initials(name.isEmpty ? '?' : name), size: 56),
            const SizedBox(width: PsSpacing.s4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name.isEmpty ? l10n.superAdminRole : name,
                      style: const TextStyle(
                          fontSize: PsType.title,
                          fontWeight: PsType.weightBlack,
                          color: PsColors.text)),
                  const SizedBox(height: 2),
                  Text(l10n.superAdminRole,
                      style: const TextStyle(
                          fontSize: PsType.subhead,
                          fontWeight: PsType.weightBold,
                          color: PsColors.accentPrimary)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: PsSpacing.s5),

        // ---- App-wide defaults -----------------------------------------------
        PsSettingsGroup.header(l10n.appDefaults),
        PsSettingsGroup(children: [
          PsSettingsRow(label: l10n.defaultLanguageNew, value: 'ქა · EN'),
          PsSettingsRow(label: l10n.defaultCurrency, value: '₾ GEL'),
          PsSettingsRow(label: l10n.reservationExpiry, value: '30 ${l10n.minutesShort}'),
          PsSettingsRow(label: l10n.maxPlayersTable, value: '9'),
        ]),
        const SizedBox(height: PsSpacing.s5),

        // ---- Feature flags (read-only in MVP) --------------------------------
        PsSettingsGroup.header(l10n.featureFlags),
        PsSettingsGroup(children: [
          _flag(l10n, l10n.ffClubChat, true),
          _flag(l10n, l10n.ffNoShow, true),
          _flag(l10n, l10n.ffAnalytics, true),
          _flag(l10n, l10n.ffGeo, false),
          _flag(l10n, l10n.ffMultiClub, false),
          _flag(l10n, l10n.ffIos, false),
        ]),
        const SizedBox(height: PsSpacing.s5),

        // ---- System health ---------------------------------------------------
        PsSettingsGroup.header(l10n.systemHealth),
        PsSettingsGroup(children: [
          PsSettingsRow(label: l10n.totalClubs, value: '${clubs.length} · $activeClubs ${l10n.activeLabel.toLowerCase()}'),
          PsSettingsRow(
            label: l10n.registeredUsers,
            sub: '$players / $pitbosses / $admins · ${l10n.usersBreakdown}',
            value: '${users.length}',
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
      ],
    );
  }

  Widget _flag(AppL10n l10n, String label, bool on) => PsSettingsRow(
        label: label,
        trailing: Text(on ? l10n.onLabel : l10n.offLabel,
            style: TextStyle(
                fontSize: PsType.subhead,
                fontWeight: PsType.weightBlack,
                color: on ? PsColors.accentPrimary : PsColors.textFaint)),
      );
}

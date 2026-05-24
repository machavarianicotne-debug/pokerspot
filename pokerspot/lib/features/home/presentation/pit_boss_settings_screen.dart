import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';
import 'package:pokerspot/shared/widgets/ps_avatar.dart';
import 'package:pokerspot/shared/widgets/ps_button.dart';
import 'package:pokerspot/shared/widgets/ps_settings_group.dart';
import 'package:pokerspot/shared/widgets/ps_toggle.dart';

/// Pit Boss Settings tab (mockup `pit-boss-settings`): availability +
/// notification toggles + sign-out. Toggle prefs are local UI state for now
/// (no persistence yet — deferred per spec).
class PitBossSettingsScreen extends ConsumerStatefulWidget {
  const PitBossSettingsScreen({super.key});

  @override
  ConsumerState<PitBossSettingsScreen> createState() => _PitBossSettingsScreenState();
}

class _PitBossSettingsScreenState extends ConsumerState<PitBossSettingsScreen> {
  bool _available = true;
  bool _newPlayer = true;
  bool _reservation = true;

  String _initials(String s) {
    final parts = s.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return (parts.length == 1
            ? (parts.first.length >= 2 ? parts.first.substring(0, 2) : parts.first)
            : parts.first[0] + parts.last[0])
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final name = user == null ? '' : '${user.firstName} ${user.lastName}'.trim();

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
                  Text(name.isEmpty ? l10n.pitBossHome : name,
                      style: const TextStyle(
                          fontSize: PsType.title,
                          fontWeight: PsType.weightBlack,
                          color: PsColors.text)),
                  const SizedBox(height: 2),
                  Text(l10n.pitBossHome,
                      style: TextStyle(fontSize: PsType.body, color: PsColors.textMuted)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: PsSpacing.s6),
        PsSettingsGroup.header(l10n.availabilityHeader),
        PsSettingsGroup(children: [
          PsSettingsRow(
            label: l10n.availableLabel,
            trailing: PsToggle(value: _available, onChanged: (v) => setState(() => _available = v)),
          ),
        ]),
        const SizedBox(height: PsSpacing.s5),
        PsSettingsGroup.header(l10n.notificationsHeader),
        PsSettingsGroup(children: [
          PsSettingsRow(
            label: l10n.joinWaitlist,
            trailing: PsToggle(value: _newPlayer, onChanged: (v) => setState(() => _newPlayer = v)),
          ),
          PsSettingsRow(
            label: l10n.notifReservation,
            trailing: PsToggle(value: _reservation, onChanged: (v) => setState(() => _reservation = v)),
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
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';
import 'package:pokerspot/features/clubs/presentation/providers.dart';
import 'package:pokerspot/shared/widgets/ps_avatar.dart';
import 'package:pokerspot/shared/widgets/ps_button.dart';
import 'package:pokerspot/shared/widgets/ps_settings_group.dart';
import 'package:pokerspot/shared/widgets/ps_toggle.dart';

/// Pit Boss Settings tab (mockup `pit-boss-settings`): profile card, availability
/// + live status pill, the five notification toggles, a language picker and the
/// account actions. Toggle/language prefs are local UI state for now (no
/// persistence yet — deferred per spec). Edit-name, Step-down and Reset-demo are
/// deferred: they need backend the MVP doesn't have (profile-write, a role-change
/// request workflow, and a demo-data concept that doesn't exist in a live app).
class PitBossSettingsScreen extends ConsumerStatefulWidget {
  const PitBossSettingsScreen({super.key});

  @override
  ConsumerState<PitBossSettingsScreen> createState() => _PitBossSettingsScreenState();
}

class _PitBossSettingsScreenState extends ConsumerState<PitBossSettingsScreen> {
  bool _available = true;
  bool _notifWaitlist = true;
  bool _notifReservation = true;
  bool _notifChat = true;
  bool _notifDecision = true;
  bool _notifDaily = false;
  String? _lang; // local highlight; persistent locale switching is deferred.

  static const _langs = [('ka', 'ქა'), ('en', 'EN'), ('ru', 'РУ')];

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
    final club = user?.clubId == null ? null : ref.watch(clubProvider(user!.clubId!)).valueOrNull;
    final role = club == null ? l10n.pitBossHome : '${l10n.pitBossHome} · ${club.name}';
    final lang = _lang ?? user?.lang ?? 'en';

    return ListView(
      padding: const EdgeInsets.fromLTRB(PsSpacing.s4, PsSpacing.s4, PsSpacing.s4, 96),
      children: [
        _profileCard(name, role, user?.phone ?? ''),
        const SizedBox(height: PsSpacing.s5),

        // ---- availability + live status pill ---------------------------------
        PsSettingsGroup.header(l10n.availabilityHeader),
        PsSettingsGroup(children: [
          PsSettingsRow(
            label: l10n.availableForChat,
            sub: l10n.availableForChatSub,
            trailing: PsToggle(value: _available, onChanged: (v) => setState(() => _available = v)),
          ),
          PsSettingsRow(
            label: l10n.statusLabel,
            trailing: _statusPill(
                _available ? l10n.statusOnline : l10n.statusUnavailable, _available),
          ),
        ]),
        const SizedBox(height: PsSpacing.s5),

        // ---- the five notification toggles -----------------------------------
        PsSettingsGroup.header(l10n.notificationsHeader),
        PsSettingsGroup(children: [
          PsSettingsRow(
            label: l10n.notifNewWaitlist,
            trailing: PsToggle(value: _notifWaitlist, onChanged: (v) => setState(() => _notifWaitlist = v)),
          ),
          PsSettingsRow(
            label: l10n.notifNewReservation,
            trailing: PsToggle(value: _notifReservation, onChanged: (v) => setState(() => _notifReservation = v)),
          ),
          PsSettingsRow(
            label: l10n.notifNewChat,
            trailing: PsToggle(value: _notifChat, onChanged: (v) => setState(() => _notifChat = v)),
          ),
          PsSettingsRow(
            label: l10n.notifReservationDecision,
            trailing: PsToggle(value: _notifDecision, onChanged: (v) => setState(() => _notifDecision = v)),
          ),
          PsSettingsRow(
            label: l10n.notifDailySummary,
            trailing: PsToggle(value: _notifDaily, onChanged: (v) => setState(() => _notifDaily = v)),
          ),
        ]),
        const SizedBox(height: PsSpacing.s5),

        // ---- language mini-picker --------------------------------------------
        PsSettingsGroup.header(l10n.languageHeader),
        PsSettingsGroup(children: [
          PsSettingsRow(
            label: l10n.appLanguage,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (code, label) in _langs)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: _langPill(label, active: lang == code, onTap: () => setState(() => _lang = code)),
                  ),
              ],
            ),
          ),
        ]),
        const SizedBox(height: PsSpacing.s6),

        // ---- account ---------------------------------------------------------
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

  Widget _profileCard(String name, String role, String phone) {
    return Container(
      padding: const EdgeInsets.all(PsSpacing.s4),
      decoration: BoxDecoration(
        color: PsColors.glassThin,
        borderRadius: BorderRadius.circular(PsRadii.lg),
        border: Border.all(color: PsColors.glassBorder),
      ),
      child: Row(
        children: [
          PsAvatar(initials: _initials(name.isEmpty ? '?' : name), size: 60),
          const SizedBox(width: PsSpacing.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name.isEmpty ? role : name,
                    style: const TextStyle(
                        fontSize: PsType.headline,
                        fontWeight: PsType.weightBlack,
                        color: PsColors.text)),
                const SizedBox(height: 2),
                Text(role,
                    style: const TextStyle(
                        fontSize: PsType.subhead,
                        fontWeight: PsType.weightBold,
                        color: PsColors.accentPrimary)),
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(phone, style: TextStyle(fontSize: PsType.caption, color: PsColors.textMuted)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusPill(String label, bool on) {
    final color = on ? PsColors.accentPrimary : PsColors.statusLive;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 7),
          Text(label,
              style: TextStyle(
                  fontSize: PsType.caption, fontWeight: PsType.weightBlack, color: color)),
        ],
      ),
    );
  }

  Widget _langPill(String label, {required bool active, required VoidCallback onTap}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: active ? PsColors.accentPrimary.withValues(alpha: 0.12) : PsColors.glassRegular,
          borderRadius: BorderRadius.circular(PsRadii.full),
          border: Border.all(color: active ? PsColors.accentPrimary : PsColors.glassBorder),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: PsType.caption,
                fontWeight: PsType.weightBold,
                color: active ? PsColors.accentPrimary : PsColors.textMuted)),
      ),
    );
  }
}

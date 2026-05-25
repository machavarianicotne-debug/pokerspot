import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';
import 'package:pokerspot/features/tournaments/domain/tournament.dart';
import 'package:pokerspot/features/tournaments/domain/tournament_registration.dart';
import 'package:pokerspot/features/tournaments/presentation/providers.dart';
import 'package:pokerspot/features/tournaments/presentation/tournament_editor_screen.dart' show tournamentTypeLabel;
import 'package:pokerspot/shared/widgets/ps_button.dart';
import 'package:pokerspot/shared/widgets/ps_card.dart';
import 'package:pokerspot/shared/widgets/ps_scaffold.dart';
import 'package:pokerspot/shared/widgets/ps_settings_group.dart';

String tournamentMoney(String currency, num? v) {
  if (v == null) return '—';
  final sym = currency == 'USD' ? '\$' : currency == 'EUR' ? '€' : '₾';
  return '$sym${v % 1 == 0 ? v.toInt() : v}';
}

String _two(int n) => n.toString().padLeft(2, '0');

String tournamentWhen(Tournament t) {
  final s = t.startAt;
  if (s == null) return '—';
  return '${_two(s.day)}.${_two(s.month)}.${s.year} · ${_two(s.hour)}:${_two(s.minute)}';
}

/// Player view of one tournament (type / buy-in / rebuy / add-on / blinds / date)
/// plus self sign-up: register up to `maxPlayers`, then onto a waitlist.
class TournamentDetailScreen extends ConsumerStatefulWidget {
  const TournamentDetailScreen({super.key, required this.tournament});

  final Tournament tournament;

  @override
  ConsumerState<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends ConsumerState<TournamentDetailScreen> {
  bool _busy = false;

  Tournament get t => widget.tournament;

  Future<void> _register() async {
    final uid = ref.read(uidProvider).valueOrNull;
    if (uid == null) return;
    final user = ref.read(currentUserProvider).valueOrNull;
    final name = user == null ? '' : '${user.firstName} ${user.lastName}'.trim();
    setState(() => _busy = true);
    await ref.read(tournamentRegistrationsRepositoryProvider).register(TournamentRegistration(
          id: '',
          tournamentId: t.id,
          clubId: t.clubId,
          playerUid: uid,
          playerName: name,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ));
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _unregister() async {
    final uid = ref.read(uidProvider).valueOrNull;
    if (uid == null) return;
    setState(() => _busy = true);
    await ref.read(tournamentRegistrationsRepositoryProvider).unregister(t.id, uid);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final cur = t.currency;
    final uid = ref.watch(uidProvider).valueOrNull;
    final regs = ref.watch(tournamentRegistrationsProvider(t.id)).valueOrNull ??
        const <TournamentRegistration>[];

    final total = regs.length;
    final max = t.maxPlayers;
    final registeredCount = max == null ? total : (total < max ? total : max);
    final waitlistCount = max == null ? 0 : (total > max ? total - max : 0);
    final isFull = max != null && total >= max;

    final myIndex = uid == null ? -1 : regs.indexWhere((r) => r.playerUid == uid);
    final iAmIn = myIndex >= 0;
    final iAmRegistered = iAmIn && (max == null || myIndex < max);
    final iAmWaitlisted = iAmIn && !iAmRegistered;
    final myWaitlistPos = iAmWaitlisted ? myIndex - max! + 1 : 0;

    final registeredValue =
        max == null ? '$total' : '$registeredCount / $max';

    return PsScaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(PsSpacing.s3, PsSpacing.s2, PsSpacing.s4, PsSpacing.s3),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.all(PsSpacing.s2),
                      child: Icon(Icons.arrow_back_ios_new, size: 18, color: PsColors.text),
                    ),
                  ),
                  const SizedBox(width: PsSpacing.s2),
                  Expanded(
                    child: Text(t.name.isEmpty ? tournamentTypeLabel(t.type, l10n) : t.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: PsType.title,
                            fontWeight: PsType.weightBlack,
                            letterSpacing: PsType.trackingSnug,
                            color: PsColors.text)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(PsSpacing.s5),
                children: [
                  PsCard(
                    accentRail: PsColors.accentSecondary,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('🏆 ${tournamentTypeLabel(t.type, l10n)}',
                            style: const TextStyle(
                                fontSize: PsType.headline,
                                fontWeight: PsType.weightBlack,
                                color: PsColors.text)),
                        const SizedBox(height: 4),
                        Text(tournamentWhen(t),
                            style: const TextStyle(
                                fontSize: PsType.body,
                                fontWeight: PsType.weightBold,
                                color: PsColors.accentPrimary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: PsSpacing.s4),
                  PsSettingsGroup(children: [
                    PsSettingsRow(label: l10n.tournamentType, value: tournamentTypeLabel(t.type, l10n)),
                    PsSettingsRow(label: l10n.buyInLabel, value: tournamentMoney(cur, t.buyIn)),
                    if (t.type.hasRebuy)
                      PsSettingsRow(label: l10n.rebuyFeeLabel, value: tournamentMoney(cur, t.rebuyFee)),
                    if (t.hasAddon)
                      PsSettingsRow(label: l10n.addonFeeLabel, value: tournamentMoney(cur, t.addonFee)),
                    PsSettingsRow(label: l10n.blindMinutesLabel, value: '${t.blindMinutes}'),
                    PsSettingsRow(
                        label: l10n.maxPlayersLabel,
                        value: max == null ? l10n.unlimitedLabel : '$max'),
                    PsSettingsRow(label: l10n.registeredLabel, value: registeredValue),
                    if (waitlistCount > 0)
                      PsSettingsRow(label: l10n.onWaitlistLabel, value: '$waitlistCount'),
                    PsSettingsRow(label: l10n.startsLabel, value: tournamentWhen(t)),
                  ]),
                  const SizedBox(height: PsSpacing.s5),
                  if (iAmRegistered)
                    _StatusBanner(
                      icon: Icons.check_circle,
                      color: PsColors.statusLive,
                      title: l10n.youAreRegisteredLabel,
                    )
                  else if (iAmWaitlisted)
                    _StatusBanner(
                      icon: Icons.hourglass_top,
                      color: PsColors.accentPrimary,
                      title: l10n.onWaitlistLabel,
                      trailing: '#$myWaitlistPos',
                    ),
                  if (iAmIn) const SizedBox(height: PsSpacing.s3),
                  PsButton(
                    key: const Key('tournamentRegisterBtn'),
                    label: iAmRegistered
                        ? l10n.cancelRegistrationBtn
                        : iAmWaitlisted
                            ? l10n.leaveWaitlistBtn
                            : isFull
                                ? l10n.joinWaitlistBtn
                                : l10n.registerBtn,
                    variant: iAmIn ? PsButtonVariant.secondary : PsButtonVariant.primary,
                    onPressed: _busy
                        ? null
                        : () => unawaited(iAmIn ? _unregister() : _register()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.icon, required this.color, required this.title, this.trailing});
  final IconData icon;
  final Color color;
  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: PsSpacing.s4, vertical: PsSpacing.s3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(PsRadii.md),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: PsSpacing.s2),
          Expanded(
            child: Text(title,
                style: TextStyle(
                    fontSize: PsType.body, fontWeight: PsType.weightBlack, color: color)),
          ),
          if (trailing != null)
            Text(trailing!,
                style: TextStyle(
                    fontSize: PsType.headline, fontWeight: PsType.weightBlack, color: color)),
        ],
      ),
    );
  }
}

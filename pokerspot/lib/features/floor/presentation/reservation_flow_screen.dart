import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';
import 'package:pokerspot/features/clubs/domain/club.dart';
import 'package:pokerspot/features/clubs/presentation/providers.dart';
import 'package:pokerspot/features/floor/domain/poker_table.dart';
import 'package:pokerspot/features/floor/domain/stakes.dart';
import 'package:pokerspot/features/floor/presentation/providers.dart';
import 'package:pokerspot/shared/widgets/ps_button.dart';
import 'package:pokerspot/shared/widgets/ps_countdown.dart';
import 'package:pokerspot/shared/widgets/ps_filter_pill.dart';
import 'package:pokerspot/shared/widgets/ps_overline.dart';
import 'package:pokerspot/shared/widgets/ps_scaffold.dart';

/// Player reserves a seat (mockup `reservation-flow`): pick a stake → instant
/// 30-minute hold → success state. Reachable from the club details "Reserve".
class ReservationFlowScreen extends ConsumerStatefulWidget {
  const ReservationFlowScreen({super.key, required this.clubId});
  final String clubId;

  @override
  ConsumerState<ReservationFlowScreen> createState() => _ReservationFlowScreenState();
}

class _ReservationFlowScreenState extends ConsumerState<ReservationFlowScreen> {
  Stakes? _selected;
  bool _held = false;
  bool _busy = false;

  Future<void> _reserve(Stakes stakes) async {
    setState(() => _busy = true);
    final uid = ref.read(authRepositoryProvider).currentUid;
    final user = ref.read(currentUserProvider).valueOrNull;
    if (uid != null) {
      await ref.read(reservationsRepositoryProvider).reserve(
            clubId: widget.clubId,
            playerUid: uid,
            playerName: user == null ? '' : '${user.firstName} ${user.lastName}'.trim(),
            stakes: stakes,
          );
    }
    if (mounted) setState(() => _held = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final club = ref.watch(clubProvider(widget.clubId)).valueOrNull;
    final tables = ref.watch(tablesProvider(widget.clubId)).valueOrNull ?? const <PokerTable>[];
    final games = {for (final g in club?.games ?? const <ClubGame>[]) g.label: g};
    // Reservation is allowed when a stake has an OPEN seat, OR when nobody is on
    // its waitlist (reservation has priority over a not-yet-formed queue). It is
    // blocked only when there's no seat AND at least one person is waiting.
    final byLabel = <String, Stakes>{for (final t in tables) t.stakes.label: t.stakes};
    final reservable = <Stakes>[
      for (final e in byLabel.entries)
        if ((games[e.key]?.openSeats ?? 0) > 0 || (games[e.key]?.waiting ?? 0) == 0) e.value,
    ];
    final reservableLabels = reservable.map((s) => s.label).toSet();
    if (_selected != null && !reservableLabels.contains(_selected!.label)) _selected = null;
    _selected ??= reservable.isNotEmpty ? reservable.first : null;

    if (_held) return _success(context, l10n);

    return PsScaffold(
      body: SafeArea(
        child: Column(
          children: [
            _nav(context, l10n.reserveSeat),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(PsSpacing.s5),
                children: [
                  Row(
                    children: [
                      _LogoOrb(name: club?.name ?? '?'),
                      const SizedBox(width: PsSpacing.s3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(club?.name ?? l10n.clubsListTitle,
                                style: const TextStyle(
                                    fontSize: PsType.headline,
                                    fontWeight: PsType.weightBlack,
                                    color: PsColors.text)),
                            const SizedBox(height: 2),
                            PsOverline(club?.city ?? ''),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: PsSpacing.s5),
                  PsOverline(l10n.chooseStake),
                  const SizedBox(height: PsSpacing.s3),
                  if (reservable.isEmpty)
                    Text(l10n.noOpenSeats,
                        style: TextStyle(fontSize: PsType.subhead, height: 1.4, color: PsColors.textMuted))
                  else
                    Wrap(
                      spacing: PsSpacing.s2,
                      runSpacing: PsSpacing.s2,
                      children: [
                        for (final s in reservable)
                          PsFilterPill(
                            label: (games[s.label]?.openSeats ?? 0) > 0
                                ? '${s.label} · ${games[s.label]!.openSeats} ${l10n.openShort}'
                                : s.label,
                            active: _selected?.label == s.label,
                            onTap: () => setState(() => _selected = s),
                          ),
                      ],
                    ),
                  const SizedBox(height: PsSpacing.s5),
                  _holdInfo(l10n),
                  const SizedBox(height: PsSpacing.s6),
                  SizedBox(
                    width: double.infinity,
                    child: PsButton(
                      key: const Key('reserveNowBtn'),
                      label: l10n.reserveNow,
                      icon: Icons.event_available,
                      onPressed: (_selected == null || _busy) ? null : () => unawaited(_reserve(_selected!)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _success(BuildContext context, AppL10n l10n) {
    return PsScaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(PsSpacing.s8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 92,
                  height: 92,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: PsColors.accentPrimary,
                    boxShadow: [
                      BoxShadow(color: PsColors.accentPrimary, blurRadius: 50, spreadRadius: -6),
                    ],
                  ),
                  child: const Icon(Icons.check, size: 44, color: PsColors.onAccent),
                ),
                const SizedBox(height: PsSpacing.s4),
                Text(l10n.seatHeldTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: PsType.title,
                        fontWeight: PsType.weightBlack,
                        color: PsColors.text)),
                const SizedBox(height: PsSpacing.s3),
                PsCountdown(
                  deadline: DateTime.now().add(const Duration(minutes: 30)),
                  color: PsColors.accentPrimary,
                  style: const TextStyle(fontSize: PsType.display2, fontWeight: PsType.weightBlack),
                ),
                const SizedBox(height: PsSpacing.s6),
                SizedBox(
                  width: 220,
                  child: PsButton(
                    key: const Key('reserveDoneBtn'),
                    label: l10n.backToClubs,
                    variant: PsButtonVariant.secondary,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _holdInfo(AppL10n l10n) => Container(
        padding: const EdgeInsets.all(PsSpacing.s4),
        decoration: BoxDecoration(
          color: PsColors.glassThin,
          borderRadius: BorderRadius.circular(PsRadii.md),
          border: Border.all(color: PsColors.glassBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.schedule, size: 18, color: PsColors.accentPrimary),
            const SizedBox(width: PsSpacing.s3),
            Expanded(
              child: Text(l10n.holdInfoText,
                  style: TextStyle(fontSize: PsType.subhead, height: 1.4, color: PsColors.textMuted)),
            ),
          ],
        ),
      );

  Widget _nav(BuildContext context, String title) => Padding(
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
            Text(title,
                style: const TextStyle(
                    fontSize: PsType.body, fontWeight: PsType.weightBold, color: PsColors.text)),
          ],
        ),
      );
}

class _LogoOrb extends StatelessWidget {
  const _LogoOrb({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final letter = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(PsRadii.md),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [PsColors.accentPrimary, PsColors.accentSecondary],
        ),
      ),
      child: Text(letter,
          style: const TextStyle(
              fontSize: 20, fontWeight: PsType.weightBlack, color: PsColors.onAccent)),
    );
  }
}

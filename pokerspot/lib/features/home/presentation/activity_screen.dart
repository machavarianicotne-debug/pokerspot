import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/features/floor/domain/reservation.dart';
import 'package:pokerspot/features/floor/domain/session.dart';
import 'package:pokerspot/features/floor/presentation/my_waitlist_banner.dart';
import 'package:pokerspot/features/floor/presentation/providers.dart';
import 'package:pokerspot/shared/widgets/ps_card.dart';
import 'package:pokerspot/shared/widgets/ps_countdown.dart';
import 'package:pokerspot/shared/widgets/ps_list_tile.dart';
import 'package:pokerspot/shared/widgets/ps_live_dot.dart';

/// The player's Activity tab: active session(s), held reservations (with a live
/// countdown), and the waitlist banner; an empty state when there's nothing.
class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final entries = ref.watch(myWaitlistProvider).valueOrNull ?? const [];
    final sessions = ref.watch(mySessionProvider).valueOrNull ?? const <Session>[];
    final reservations = ref.watch(myReservationsProvider).valueOrNull ?? const <Reservation>[];

    if (entries.isEmpty && sessions.isEmpty && reservations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(PsSpacing.s5),
          child: Text(
            l10n.noActivityYet,
            textAlign: TextAlign.center,
            style: TextStyle(color: PsColors.textMuted, fontSize: PsType.body),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, PsSpacing.s2, 0, 96),
      children: [
        for (final s in sessions)
          Padding(
            padding: const EdgeInsets.fromLTRB(PsSpacing.s4, 0, PsSpacing.s4, PsSpacing.s3),
            child: _SessionCard(session: s),
          ),
        for (final r in reservations)
          Padding(
            padding: const EdgeInsets.fromLTRB(PsSpacing.s4, 0, PsSpacing.s4, PsSpacing.s3),
            child: _ReservationCard(reservation: r),
          ),
        const MyWaitlistBanner(),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session});
  final Session session;

  @override
  Widget build(BuildContext context) {
    return PsCard(
      accentRail: PsColors.accentPrimary,
      child: PsListTile(
        title: session.stakes.label,
        subtitle: '#${session.seatNumber}',
        trailing: const SizedBox(width: 16, child: Center(child: PsLiveDot())),
      ),
    );
  }
}

class _ReservationCard extends ConsumerWidget {
  const _ReservationCard({required this.reservation});
  final Reservation reservation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final until = reservation.heldUntil;
    return PsCard(
      accentRail: PsColors.accentSecondary,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reservation.stakes.label,
                    style: const TextStyle(
                        fontSize: PsType.body,
                        fontWeight: PsType.weightBold,
                        color: PsColors.text)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text('${l10n.reservedBadge} · ',
                        style: TextStyle(fontSize: PsType.subhead, color: PsColors.textMuted)),
                    if (until != null)
                      PsCountdown(deadline: until, color: PsColors.accentSecondary),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            key: Key('cancelReservation_${reservation.id}'),
            onTap: () => unawaited(ref.read(reservationsRepositoryProvider).cancel(reservation.id)),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: PsSpacing.s2, vertical: PsSpacing.s1),
              child: Text(
                l10n.cancelWaitlist,
                style: const TextStyle(
                    fontSize: PsType.subhead,
                    fontWeight: PsType.weightBold,
                    color: PsColors.statusLive),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

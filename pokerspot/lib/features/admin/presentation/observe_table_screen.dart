import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/features/floor/domain/poker_table.dart';
import 'package:pokerspot/features/floor/domain/reservation.dart';
import 'package:pokerspot/features/floor/domain/session.dart';
import 'package:pokerspot/features/floor/domain/waitlist_entry.dart';
import 'package:pokerspot/features/floor/presentation/providers.dart';
import 'package:pokerspot/shared/widgets/ps_card.dart';
import 'package:pokerspot/shared/widgets/ps_countdown.dart';
import 'package:pokerspot/shared/widgets/ps_overline.dart';
import 'package:pokerspot/shared/widgets/ps_scaffold.dart';
import 'package:pokerspot/shared/widgets/ps_seat_map.dart';

String _sym(String c) => c == 'USD' ? '\$' : c == 'EUR' ? '€' : '₾';
String _money(String c, num? v) => v == null ? '—' : '${_sym(c)}${v % 1 == 0 ? v.toInt() : v}';
String _fmt(num n) => n % 1 == 0 ? n.toInt().toString() : '$n';

/// Super Admin read-only single-table view (mockup `super-admin-observe-table`):
/// seat map + meta + waitlist + reservations, all non-interactive.
class ObserveTableScreen extends ConsumerWidget {
  const ObserveTableScreen({super.key, required this.clubId, required this.table});
  final String clubId;
  final PokerTable table;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final sessions = ref.watch(clubSessionsProvider(clubId)).valueOrNull ?? const <Session>[];
    final bySeat = <int, Session>{
      for (final s in sessions)
        if (s.tableId == table.id) s.seatNumber: s,
    };
    final waiting = (ref.watch(clubWaitlistProvider(clubId)).valueOrNull ?? const <WaitlistEntry>[])
        .where((e) => e.stakes.label == table.stakes.label)
        .toList();
    final reservations =
        (ref.watch(clubReservationsProvider(clubId)).valueOrNull ?? const <Reservation>[])
            .where((r) => r.stakes.label == table.stakes.label && r.status == ReservationStatus.held)
            .toList();
    final cur = table.stakes.currency;

    return PsScaffold(
      body: SafeArea(
        child: Column(
          children: [
            _nav(context, '${l10n.tableLabel} ${table.number} · ${table.stakes.label}', l10n),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(PsSpacing.s5),
                children: [
                  PsCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PsSeatMap(
                          seatCount: table.seatCount,
                          filledSeats: bySeat.keys.toSet(),
                        ),
                        const SizedBox(height: PsSpacing.s3),
                        _meta(l10n.blindsLabel, '${_fmt(table.stakes.smallBlind)}/${_fmt(table.stakes.bigBlind)}'),
                        _meta(l10n.avgStackLabel, _money(cur, table.avgStack)),
                        _meta(l10n.minBuyInLabel, _money(cur, table.minBuyIn)),
                      ],
                    ),
                  ),
                  if (waiting.isNotEmpty) ...[
                    const SizedBox(height: PsSpacing.s4),
                    PsOverline('${l10n.waitlistTitle} · ${waiting.length}'),
                    const SizedBox(height: PsSpacing.s2),
                    for (var i = 0; i < waiting.length; i++)
                      _roRow('${i + 1}', waiting[i].playerName, null),
                  ],
                  if (reservations.isNotEmpty) ...[
                    const SizedBox(height: PsSpacing.s4),
                    PsOverline('${l10n.reservationsTitle} · ${reservations.length} ${l10n.heldLabel}'),
                    const SizedBox(height: PsSpacing.s2),
                    for (final r in reservations)
                      _roRow(null, r.playerName, r.heldUntil),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _meta(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: PsSpacing.s2),
        child: Row(
          children: [
            SizedBox(
              width: 96,
              child: Text(k,
                  style: TextStyle(
                      fontSize: PsType.subhead,
                      fontWeight: PsType.weightMedium,
                      color: PsColors.textMuted)),
            ),
            Text(v,
                style: const TextStyle(
                    fontSize: PsType.headline,
                    fontWeight: PsType.weightBlack,
                    color: PsColors.text)),
          ],
        ),
      );

  Widget _roRow(String? pos, String name, DateTime? until) => Padding(
        padding: const EdgeInsets.only(bottom: PsSpacing.s2),
        child: PsCard(
          child: Row(
            children: [
              if (pos != null) ...[
                SizedBox(
                  width: 20,
                  child: Text(pos,
                      style: const TextStyle(
                          fontSize: PsType.body,
                          fontWeight: PsType.weightBlack,
                          color: PsColors.accentPrimary)),
                ),
                const SizedBox(width: PsSpacing.s2),
              ],
              Expanded(
                child: Text(name.isEmpty ? '—' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: PsType.body,
                        fontWeight: PsType.weightBold,
                        color: PsColors.text)),
              ),
              if (until != null) PsCountdown(deadline: until),
            ],
          ),
        ),
      );

  Widget _nav(BuildContext context, String title, AppL10n l10n) => Padding(
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
              child: Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: PsType.body,
                      fontWeight: PsType.weightBold,
                      color: PsColors.text)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: PsColors.glassRegular,
                borderRadius: BorderRadius.circular(PsRadii.full),
                border: Border.all(color: PsColors.glassBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.visibility_outlined, size: 13, color: PsColors.textMuted),
                  const SizedBox(width: 5),
                  Text(l10n.readOnlyLabel,
                      style: TextStyle(
                          fontSize: PsType.micro,
                          fontWeight: PsType.weightBlack,
                          color: PsColors.textMuted)),
                ],
              ),
            ),
          ],
        ),
      );
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/features/floor/domain/poker_table.dart';
import 'package:pokerspot/features/floor/domain/session.dart';
import 'package:pokerspot/features/floor/domain/waitlist_entry.dart';
import 'package:pokerspot/features/floor/presentation/providers.dart';
import 'package:pokerspot/features/floor/presentation/table_editor_sheet.dart';
import 'package:pokerspot/shared/widgets/ps_button.dart';
import 'package:pokerspot/shared/widgets/ps_card.dart';
import 'package:pokerspot/shared/widgets/ps_scaffold.dart';
import 'package:pokerspot/shared/widgets/ps_seat_map.dart';
import 'package:pokerspot/shared/widgets/ps_sheet.dart';

/// A seated session running longer than this glows as a warning (mockup 8h).
const _sessionWarn = Duration(hours: 8);

/// Visual seat map for one table: occupied seats show initials, free seats are
/// tappable to seat a called/waiting player or a walk-in. Edit/delete in the nav.
class TableDetailScreen extends ConsumerWidget {
  const TableDetailScreen({super.key, required this.clubId, required this.tableId});
  final String clubId;
  final String tableId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final tables = ref.watch(tablesProvider(clubId)).valueOrNull ?? const <PokerTable>[];
    PokerTable? table;
    for (final t in tables) {
      if (t.id == tableId) table = t;
    }
    final sessions = ref.watch(clubSessionsProvider(clubId)).valueOrNull ?? const <Session>[];
    final bySeat = <int, Session>{};
    for (final s in sessions) {
      if (s.tableId == tableId) bySeat[s.seatNumber] = s;
    }

    final t = table;
    return PsScaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Nav(
              title: t == null ? l10n.tableLabel : '${l10n.tableLabel} ${t.number}',
              onEdit: t == null ? null : () => TableEditorSheet.show(context, clubId: clubId, existing: t),
              onDelete: t == null ? null : () => _confirmDelete(context, ref, t),
            ),
            if (t == null)
              Expanded(child: Center(child: Text(l10n.noTablesYet, style: TextStyle(color: PsColors.textMuted))))
            else
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(PsSpacing.s5),
                  children: [
                    PsCard(
                      accentRail: t.open ? PsColors.accentPrimary : PsColors.statusClosed,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.stakes.label,
                              style: const TextStyle(
                                  fontSize: PsType.title,
                                  fontWeight: PsType.weightBlack,
                                  letterSpacing: PsType.trackingSnug,
                                  color: PsColors.text)),
                          const SizedBox(height: 4),
                          Text('${bySeat.length}/${t.seatCount}${t.open ? ' · ${l10n.openLabel}' : ''}',
                              style: TextStyle(
                                  fontSize: PsType.subhead,
                                  fontWeight: PsType.weightMedium,
                                  color: PsColors.textMuted)),
                        ],
                      ),
                    ),
                    const SizedBox(height: PsSpacing.s5),
                    PsSeatMap(
                      seatCount: t.seatCount,
                      filledSeats: bySeat.keys.toSet(),
                      warnSeats: {
                        for (final e in bySeat.entries)
                          if (_isWarn(e.value)) e.key,
                      },
                      onSeatTap: (seat) {
                        final s = bySeat[seat];
                        if (s == null) {
                          _seatPicker(context, ref, t, seat);
                        } else {
                          _endSession(context, ref, s);
                        }
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  static bool _isWarn(Session s) {
    final start = s.startedAt;
    return start != null && DateTime.now().difference(start) > _sessionWarn;
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, PokerTable t) {
    final l10n = AppL10n.of(context);
    PsSheet.show<void>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.deleteTableConfirm,
              style: const TextStyle(
                  fontSize: PsType.headline, fontWeight: PsType.weightBold, color: PsColors.text)),
          const SizedBox(height: PsSpacing.s4),
          PsButton(
            key: const Key('confirmDeleteTableBtn'),
            label: l10n.deleteTable,
            onPressed: () async {
              final nav = Navigator.of(context);
              await ref.read(tablesRepositoryProvider).deleteTable(clubId: clubId, tableId: t.id);
              nav.pop(); // sheet
              nav.pop(); // detail screen
            },
          ),
        ],
      ),
    );
  }

  void _endSession(BuildContext context, WidgetRef ref, Session s) {
    final l10n = AppL10n.of(context);
    PsSheet.show<void>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('${s.playerName} · #${s.seatNumber}',
              style: const TextStyle(
                  fontSize: PsType.headline, fontWeight: PsType.weightBold, color: PsColors.text)),
          const SizedBox(height: PsSpacing.s4),
          PsButton(
            key: Key('endSeatBtn_${s.id}'),
            label: l10n.endSession,
            variant: PsButtonVariant.secondary,
            onPressed: () {
              final nav = Navigator.of(context);
              unawaited(ref.read(sessionsRepositoryProvider).end(s.id));
              nav.pop();
            },
          ),
        ],
      ),
    );
  }

  void _seatPicker(BuildContext context, WidgetRef ref, PokerTable t, int seat) {
    PsSheet.show<void>(context, child: _SeatPicker(table: t, seat: seat));
  }
}

class _Nav extends StatelessWidget {
  const _Nav({required this.title, this.onEdit, this.onDelete});
  final String title;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                    fontSize: PsType.title,
                    fontWeight: PsType.weightBlack,
                    letterSpacing: PsType.trackingSnug,
                    color: PsColors.text)),
          ),
          if (onEdit != null)
            GestureDetector(
              key: const Key('editTableBtn'),
              onTap: onEdit,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(PsSpacing.s2),
                child: Icon(Icons.edit_outlined, size: 20, color: PsColors.textMuted),
              ),
            ),
          if (onDelete != null)
            GestureDetector(
              key: const Key('deleteTableBtn'),
              onTap: onDelete,
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.all(PsSpacing.s2),
                child: Icon(Icons.delete_outline, size: 20, color: PsColors.statusLive),
              ),
            ),
        ],
      ),
    );
  }
}

/// Choose who sits in a free seat: a called/waiting player, or a walk-in.
class _SeatPicker extends ConsumerWidget {
  const _SeatPicker({required this.table, required this.seat});
  final PokerTable table;
  final int seat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final waitlist = ref.watch(clubWaitlistProvider(table.clubId)).valueOrNull ?? const <WaitlistEntry>[];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('${l10n.seatWhoTitle} · #$seat',
            style: const TextStyle(
                fontSize: PsType.headline, fontWeight: PsType.weightBold, color: PsColors.text)),
        const SizedBox(height: PsSpacing.s3),
        for (final e in waitlist)
          Padding(
            padding: const EdgeInsets.only(bottom: PsSpacing.s2),
            child: _PickRow(
              key: Key('pick_${e.id}'),
              title: e.playerName,
              subtitle: e.stakes.label,
              onTap: () {
                final nav = Navigator.of(context);
                unawaited(ref.read(waitlistRepositoryProvider).seat(
                      entry: e,
                      tableId: table.id,
                      seatNumber: seat,
                    ));
                nav.pop();
              },
            ),
          ),
        const SizedBox(height: PsSpacing.s2),
        PsButton(
          key: const Key('walkInBtn'),
          label: l10n.walkInLabel,
          icon: Icons.directions_walk,
          variant: PsButtonVariant.secondary,
          onPressed: () {
            final nav = Navigator.of(context);
            unawaited(ref.read(sessionsRepositoryProvider).seatWalkIn(
                  clubId: table.clubId,
                  tableId: table.id,
                  seatNumber: seat,
                  stakes: table.stakes,
                  playerName: l10n.walkInLabel,
                ));
            nav.pop();
          },
        ),
      ],
    );
  }
}

class _PickRow extends StatelessWidget {
  const _PickRow({super.key, required this.title, required this.subtitle, required this.onTap});
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: PsSpacing.s4, vertical: PsSpacing.s3),
        decoration: BoxDecoration(
          color: PsColors.glassThin,
          borderRadius: BorderRadius.circular(PsRadii.md),
          border: Border.all(color: PsColors.glassBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: PsType.body,
                          fontWeight: PsType.weightBold,
                          color: PsColors.text)),
                  Text(subtitle,
                      style: TextStyle(fontSize: PsType.subhead, color: PsColors.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.add, color: PsColors.accentPrimary),
          ],
        ),
      ),
    );
  }
}

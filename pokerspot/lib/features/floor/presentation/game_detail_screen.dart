import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/features/floor/domain/poker_table.dart';
import 'package:pokerspot/features/floor/domain/session.dart';
import 'package:pokerspot/features/floor/domain/waitlist_entry.dart';
import 'package:pokerspot/features/floor/presentation/providers.dart';
import 'package:pokerspot/shared/widgets/ps_button.dart';
import 'package:pokerspot/shared/widgets/ps_card.dart';
import 'package:pokerspot/shared/widgets/ps_list_tile.dart';
import 'package:pokerspot/shared/widgets/ps_overline.dart';
import 'package:pokerspot/shared/widgets/ps_scaffold.dart';
import 'package:pokerspot/shared/widgets/ps_seat_map.dart';
import 'package:pokerspot/shared/widgets/ps_sheet.dart';
import 'package:pokerspot/shared/widgets/ps_text_field.dart';

const _sessionWarn = Duration(hours: 8);

/// Game-centric Pit Boss detail (mockup `pit-boss-table-detail`): every table of
/// one stake shown together, a **shared** waitlist, and editable blinds/avg/min
/// that mirror across all same-stake tables. Tables 2+ note they share the list.
class GameDetailScreen extends ConsumerWidget {
  const GameDetailScreen({super.key, required this.clubId, required this.stakeLabel});
  final String clubId;
  final String stakeLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final allTables = ref.watch(tablesProvider(clubId)).valueOrNull ?? const <PokerTable>[];
    final tables = allTables.where((t) => t.stakes.label == stakeLabel).toList()
      ..sort((a, b) => a.number.compareTo(b.number));
    final sessions = ref.watch(clubSessionsProvider(clubId)).valueOrNull ?? const <Session>[];
    final waitlist = (ref.watch(clubWaitlistProvider(clubId)).valueOrNull ?? const <WaitlistEntry>[])
        .where((e) => e.stakes.label == stakeLabel)
        .toList();

    return PsScaffold(
      body: SafeArea(
        child: Column(
          children: [
            _nav(context, '$stakeLabel · ${tables.length}'),
            if (tables.isEmpty)
              Expanded(child: Center(child: Text(l10n.noTablesYet, style: TextStyle(color: PsColors.textMuted))))
            else
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(PsSpacing.s5),
                  children: [
                    for (var i = 0; i < tables.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: PsSpacing.s4),
                        child: _tableCard(context, ref, tables, i, sessions),
                      ),
                    const SizedBox(height: PsSpacing.s2),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: PsOverline('${l10n.waitlistTitle} · ${waitlist.length}'),
                    ),
                    const SizedBox(height: PsSpacing.s3),
                    ..._waitlistRows(context, ref, tables, waitlist, sessions),
                    const SizedBox(height: PsSpacing.s4),
                    PsButton(
                      key: const Key('addTableBtn'),
                      label: l10n.newTable,
                      icon: Icons.add,
                      variant: PsButtonVariant.secondary,
                      onPressed: () => _addTable(ref, tables),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _tableCard(BuildContext context, WidgetRef ref, List<PokerTable> tables, int i,
      List<Session> sessions) {
    final l10n = AppL10n.of(context);
    final t = tables[i];
    final bySeat = <int, Session>{
      for (final s in sessions)
        if (s.tableId == t.id) s.seatNumber: s,
    };
    return PsCard(
      key: Key('tableCard_${t.id}'),
      accentRail: t.open ? PsColors.accentPrimary : PsColors.statusClosed,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _numOrb(t.number),
              const SizedBox(width: PsSpacing.s3),
              Text('${l10n.tableLabel} ${t.number}',
                  style: const TextStyle(
                      fontSize: PsType.headline,
                      fontWeight: PsType.weightBlack,
                      color: PsColors.text)),
              const Spacer(),
              GestureDetector(
                key: Key('closeTableBtn_${t.id}'),
                onTap: () => unawaited(ref.read(tablesRepositoryProvider).deleteTable(clubId: clubId, tableId: t.id)),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(PsSpacing.s1),
                  child: Icon(Icons.close, size: 18, color: PsColors.textFaint),
                ),
              ),
            ],
          ),
          const SizedBox(height: PsSpacing.s4),
          PsSeatMap(
            seatCount: t.seatCount,
            filledSeats: bySeat.keys.toSet(),
            warnSeats: {
              for (final e in bySeat.entries)
                if (_warn(e.value)) e.key,
            },
            onSeatTap: (seat) {
              final s = bySeat[seat];
              if (s == null) {
                _seatPicker(context, ref, tables, t, seat);
              } else {
                _endSession(context, ref, s);
              }
            },
          ),
          const SizedBox(height: PsSpacing.s3),
          _metaRow(context, ref, tables, l10n.blindsLabel, '${_fmt(t.stakes.smallBlind)}/${_fmt(t.stakes.bigBlind)}',
              (v) => _editBlinds(ref, tables, v)),
          _metaRow(context, ref, tables, l10n.avgStackLabel, t.avgStack == null ? '—' : _fmt(t.avgStack!),
              (v) => _updateAll(ref, tables, avg: num.tryParse(v))),
          _metaRow(context, ref, tables, l10n.minBuyInLabel, t.minBuyIn == null ? '—' : _fmt(t.minBuyIn!),
              (v) => _updateAll(ref, tables, min: num.tryParse(v))),
          if (i > 0)
            Padding(
              padding: const EdgeInsets.only(top: PsSpacing.s2),
              child: Text('${l10n.waitlistTitle} · ${l10n.tableLabel} ${tables.first.number}',
                  style: TextStyle(
                      fontSize: PsType.caption,
                      fontStyle: FontStyle.italic,
                      color: PsColors.textFaint)),
            ),
        ],
      ),
    );
  }

  Widget _metaRow(BuildContext context, WidgetRef ref, List<PokerTable> tables, String label,
      String value, void Function(String) onSave) {
    return GestureDetector(
      onTap: () => _editMeta(context, label, value, onSave),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: PsSpacing.s2),
        child: Row(
          children: [
            SizedBox(
              width: 96,
              child: Text(label,
                  style: TextStyle(
                      fontSize: PsType.subhead,
                      fontWeight: PsType.weightMedium,
                      color: PsColors.textMuted)),
            ),
            Text(value,
                style: const TextStyle(
                    fontSize: PsType.headline,
                    fontWeight: PsType.weightBlack,
                    color: PsColors.accentSecondary)),
            const Spacer(),
            Icon(Icons.edit_outlined, size: 14, color: PsColors.textFaint),
          ],
        ),
      ),
    );
  }

  List<Widget> _waitlistRows(BuildContext context, WidgetRef ref, List<PokerTable> tables,
      List<WaitlistEntry> waitlist, List<Session> sessions) {
    if (waitlist.isEmpty) return const [];
    // first free seat across the game's tables
    ({String tableId, int seat})? firstFree;
    for (final t in tables) {
      final taken = sessions.where((s) => s.tableId == t.id).map((s) => s.seatNumber).toSet();
      for (var n = 1; n <= t.seatCount; n++) {
        if (!taken.contains(n)) {
          firstFree = (tableId: t.id, seat: n);
          break;
        }
      }
      if (firstFree != null) break;
    }
    final l10n = AppL10n.of(context);
    return [
      for (final e in waitlist)
        Padding(
          padding: const EdgeInsets.only(bottom: PsSpacing.s2),
          child: PsCard(
            key: Key('wlRow_${e.id}'),
            child: PsListTile(
              title: e.playerName.isEmpty ? '—' : e.playerName,
              subtitle: e.status == WaitlistStatus.called ? l10n.statusCalled : l10n.statusWaiting,
              trailing: e.status == WaitlistStatus.called
                  ? PsButton(
                      key: Key('seatBtn_${e.id}'),
                      label: l10n.seatAction,
                      onPressed: firstFree == null
                          ? null
                          : () => unawaited(ref.read(waitlistRepositoryProvider).seat(
                                entry: e, tableId: firstFree!.tableId, seatNumber: firstFree.seat)),
                    )
                  : PsButton(
                      key: Key('callBtn_${e.id}'),
                      label: l10n.callAction,
                      onPressed: () => unawaited(ref.read(waitlistRepositoryProvider).call(e.id)),
                    ),
            ),
          ),
        ),
    ];
  }

  // ---- actions ------------------------------------------------------------

  void _editBlinds(WidgetRef ref, List<PokerTable> tables, String v) {
    final parts = v.split('/');
    final sb = parts.isNotEmpty ? num.tryParse(parts[0].trim()) : null;
    final bb = parts.length > 1 ? num.tryParse(parts[1].trim()) : null;
    if (sb == null || bb == null) return;
    for (final t in tables) {
      unawaited(ref.read(tablesRepositoryProvider)
          .updateTable(t.copyWith(stakes: t.stakes.copyWith(smallBlind: sb, bigBlind: bb))));
    }
  }

  void _updateAll(WidgetRef ref, List<PokerTable> tables, {num? avg, num? min}) {
    for (final t in tables) {
      unawaited(ref.read(tablesRepositoryProvider)
          .updateTable(t.copyWith(avgStack: avg ?? t.avgStack, minBuyIn: min ?? t.minBuyIn)));
    }
  }

  void _addTable(WidgetRef ref, List<PokerTable> tables) {
    if (tables.isEmpty) return;
    final first = tables.first;
    final next = tables.fold<int>(0, (m, t) => t.number > m ? t.number : m) + 1;
    unawaited(ref.read(tablesRepositoryProvider).createTable(
          clubId: clubId,
          number: next,
          stakes: first.stakes,
          seatCount: first.seatCount,
          open: true,
          avgStack: first.avgStack,
          minBuyIn: first.minBuyIn,
        ));
  }

  void _editMeta(BuildContext context, String title, String value, void Function(String) onSave) {
    final c = TextEditingController(text: value == '—' ? '' : value);
    PsSheet.show<void>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: PsType.headline, fontWeight: PsType.weightBold, color: PsColors.text)),
          const SizedBox(height: PsSpacing.s3),
          PsTextField(controller: c, autofocus: true),
          const SizedBox(height: PsSpacing.s4),
          PsButton(
            key: const Key('saveMetaBtn'),
            label: AppL10n.of(context).saveLabel,
            onPressed: () {
              onSave(c.text.trim());
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  void _seatPicker(BuildContext context, WidgetRef ref, List<PokerTable> tables, PokerTable t, int seat) {
    final l10n = AppL10n.of(context);
    final waiting = (ref.read(clubWaitlistProvider(clubId)).valueOrNull ?? const <WaitlistEntry>[])
        .where((e) => e.stakes.label == t.stakes.label)
        .toList();
    PsSheet.show<void>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('${l10n.seatWhoTitle} · #$seat',
              style: const TextStyle(
                  fontSize: PsType.headline, fontWeight: PsType.weightBold, color: PsColors.text)),
          const SizedBox(height: PsSpacing.s3),
          for (final e in waiting)
            Padding(
              padding: const EdgeInsets.only(bottom: PsSpacing.s2),
              child: PsCard(
                key: Key('pick_${e.id}'),
                onTap: () {
                  final nav = Navigator.of(context);
                  unawaited(ref.read(waitlistRepositoryProvider)
                      .seat(entry: e, tableId: t.id, seatNumber: seat));
                  nav.pop();
                },
                child: PsListTile(title: e.playerName, subtitle: e.stakes.label),
              ),
            ),
          PsButton(
            key: const Key('walkInBtn'),
            label: l10n.walkInLabel,
            icon: Icons.directions_walk,
            variant: PsButtonVariant.secondary,
            onPressed: () {
              final nav = Navigator.of(context);
              unawaited(ref.read(sessionsRepositoryProvider).seatWalkIn(
                    clubId: clubId, tableId: t.id, seatNumber: seat,
                    stakes: t.stakes, playerName: l10n.walkInLabel));
              nav.pop();
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
          ],
        ),
      );

  Widget _numOrb(int number) => Container(
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
        child: Text('$number',
            style: const TextStyle(
                fontSize: 22, fontWeight: PsType.weightBlack, color: PsColors.onAccent)),
      );

  static bool _warn(Session s) {
    final start = s.startedAt;
    return start != null && DateTime.now().difference(start) > _sessionWarn;
  }

  static String _fmt(num n) => n == n.truncate() ? n.toInt().toString() : '$n';
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/features/auth/domain/app_user.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';
import 'package:pokerspot/features/floor/domain/poker_table.dart';
import 'package:pokerspot/features/floor/domain/reservation.dart';
import 'package:pokerspot/features/floor/domain/session.dart';
import 'package:pokerspot/features/floor/domain/waitlist_entry.dart';
import 'package:pokerspot/features/floor/presentation/providers.dart';
import 'package:pokerspot/shared/widgets/ps_avatar.dart';
import 'package:pokerspot/shared/widgets/ps_button.dart';
import 'package:pokerspot/shared/widgets/ps_card.dart';
import 'package:pokerspot/shared/widgets/ps_countdown.dart';
import 'package:pokerspot/shared/widgets/ps_list_tile.dart';
import 'package:pokerspot/shared/widgets/ps_overline.dart';
import 'package:pokerspot/shared/widgets/ps_scaffold.dart';
import 'package:pokerspot/shared/widgets/ps_seat_map.dart';
import 'package:pokerspot/shared/widgets/ps_sheet.dart';
import 'package:pokerspot/shared/widgets/ps_text_field.dart';

/// A called/reservation hold lasts 30 minutes (mirrors the mockup).
const _holdWindow = Duration(minutes: 30);

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
    final reservations =
        (ref.watch(clubReservationsProvider(clubId)).valueOrNull ?? const <Reservation>[])
            .where((r) => r.stakes.label == stakeLabel && r.status == ReservationStatus.held)
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
                    Row(
                      children: [
                        PsOverline('${l10n.waitlistTitle} · ${waitlist.length}'),
                        const Spacer(),
                        GestureDetector(
                          key: const Key('addWaitlistBtn'),
                          behavior: HitTestBehavior.opaque,
                          onTap: tables.isEmpty ? null : () => _addToWaitlist(context, ref, tables.first),
                          child: Text('+ ${l10n.addLabel}'.toUpperCase(),
                              style: const TextStyle(
                                  fontSize: PsType.caption,
                                  fontWeight: PsType.weightBlack,
                                  letterSpacing: PsType.trackingWide,
                                  color: PsColors.accentPrimary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: PsSpacing.s3),
                    ..._waitlistRows(context, ref, tables, waitlist, sessions),
                    if (reservations.isNotEmpty) ...[
                      const SizedBox(height: PsSpacing.s4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: PsOverline(
                            '${l10n.reservationsTitle} · ${reservations.length} ${l10n.heldLabel}'),
                      ),
                      const SizedBox(height: PsSpacing.s3),
                      for (final r in reservations) _reservationRow(context, ref, tables, r),
                    ],
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
          if (bySeat.isNotEmpty) ...[
            const SizedBox(height: PsSpacing.s3),
            Align(
              alignment: Alignment.centerLeft,
              child: PsOverline('${l10n.seatedLabel} · ${bySeat.length}'),
            ),
            const SizedBox(height: PsSpacing.s1),
            for (final seat in (bySeat.keys.toList()..sort()))
              _seatedItem(context, ref, seat, bySeat[seat]!),
          ],
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
      for (var i = 0; i < waitlist.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: PsSpacing.s2),
          child: PsCard(
            key: Key('wlRow_${waitlist[i].id}'),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  child: Text('${i + 1}',
                      style: const TextStyle(
                          fontSize: PsType.body,
                          fontWeight: PsType.weightBlack,
                          color: PsColors.accentPrimary)),
                ),
                const SizedBox(width: PsSpacing.s2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(waitlist[i].playerName.isEmpty ? '—' : waitlist[i].playerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: PsType.body,
                              fontWeight: PsType.weightBold,
                              color: PsColors.text)),
                      if (waitlist[i].status == WaitlistStatus.called)
                        Row(
                          children: [
                            Text('${l10n.statusCalled} · ',
                                style: const TextStyle(
                                    fontSize: PsType.caption,
                                    fontWeight: PsType.weightBlack,
                                    color: PsColors.statusLive)),
                            if (waitlist[i].calledAt != null)
                              PsCountdown(
                                deadline: waitlist[i].calledAt!.add(_holdWindow),
                                style: const TextStyle(
                                    fontSize: PsType.caption, fontWeight: PsType.weightBlack),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
                _miniBtn(
                    key: Key('callBtn_${waitlist[i].id}'),
                    label: l10n.callAction,
                    primary: true,
                    onTap: () =>
                        unawaited(ref.read(waitlistRepositoryProvider).call(waitlist[i].id))),
                _miniBtn(
                    key: Key('seatBtn_${waitlist[i].id}'),
                    label: l10n.seatAction,
                    onTap: firstFree == null
                        ? null
                        : () => unawaited(ref.read(waitlistRepositoryProvider).seat(
                            entry: waitlist[i],
                            tableId: firstFree!.tableId,
                            seatNumber: firstFree.seat))),
                _miniBtn(
                    key: Key('removeWlBtn_${waitlist[i].id}'),
                    label: '✕',
                    danger: true,
                    onTap: () =>
                        unawaited(ref.read(waitlistRepositoryProvider).cancel(waitlist[i].id))),
              ],
            ),
          ),
        ),
    ];
  }

  /// Compact uppercase action chip (mockup `.wl-act button` / `.res-act button`).
  Widget _miniBtn({
    Key? key,
    required String label,
    VoidCallback? onTap,
    bool primary = false,
    bool danger = false,
  }) {
    final disabled = onTap == null;
    final fg = disabled
        ? PsColors.textFaint
        : danger
            ? PsColors.statusLive
            : primary
                ? PsColors.onAccent
                : PsColors.text;
    return GestureDetector(
      key: key,
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: PsSpacing.s1),
        padding: const EdgeInsets.symmetric(horizontal: PsSpacing.s2, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(PsRadii.sm),
          color: primary && !disabled ? PsColors.accentPrimary : PsColors.glassRegular,
          border: Border.all(color: PsColors.glassBorder),
        ),
        child: Text(label.toUpperCase(),
            style: TextStyle(
                fontSize: PsType.micro, fontWeight: PsType.weightBlack, color: fg)),
      ),
    );
  }

  /// One seated player (mockup `.seated-item`): seat badge + name (+ walk-in tag)
  /// + a live count-up session timer. Tap to end the session.
  Widget _seatedItem(BuildContext context, WidgetRef ref, int seat, Session s) {
    final l10n = AppL10n.of(context);
    final walkIn = s.playerUid.startsWith('walk-in:');
    return GestureDetector(
      key: Key('seated_${s.id}'),
      behavior: HitTestBehavior.opaque,
      onTap: () => _endSession(context, ref, s),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: PsColors.glassBorder))),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: PsColors.glassRegular,
                border: Border.all(color: PsColors.glassBorder),
              ),
              child: Text('$seat',
                  style: const TextStyle(
                      fontSize: PsType.micro, fontWeight: PsType.weightBlack, color: PsColors.text)),
            ),
            const SizedBox(width: PsSpacing.s3),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(s.playerName.isEmpty ? '—' : s.playerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: PsType.subhead,
                            fontWeight: PsType.weightBold,
                            color: PsColors.text)),
                  ),
                  if (walkIn)
                    Padding(
                      padding: const EdgeInsets.only(left: PsSpacing.s2),
                      child: Text(l10n.walkInLabel,
                          style: TextStyle(fontSize: PsType.micro, color: PsColors.textFaint)),
                    ),
                ],
              ),
            ),
            if (s.startedAt != null) _ElapsedTimer(start: s.startedAt!),
          ],
        ),
      ),
    );
  }

  /// One held reservation (mockup `.res-item`): name + live 30-min countdown +
  /// Arrived (marks arrived and adds the holder to the waitlist) / reject.
  Widget _reservationRow(
      BuildContext context, WidgetRef ref, List<PokerTable> tables, Reservation r) {
    final l10n = AppL10n.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: PsSpacing.s2),
      child: PsCard(
        key: Key('resRow_${r.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(r.playerName.isEmpty ? '—' : r.playerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: PsType.body,
                          fontWeight: PsType.weightBold,
                          color: PsColors.text)),
                ),
                if (r.heldUntil != null) PsCountdown(deadline: r.heldUntil!),
              ],
            ),
            const SizedBox(height: PsSpacing.s2),
            Row(
              children: [
                _miniBtn(
                    key: Key('arrivedBtn_${r.id}'),
                    label: l10n.arrivedAction,
                    primary: true,
                    onTap: () {
                      unawaited(ref.read(reservationsRepositoryProvider).markArrived(r.id));
                      unawaited(ref.read(waitlistRepositoryProvider).join(
                          clubId: r.clubId,
                          playerUid: r.playerUid,
                          playerName: r.playerName,
                          stakes: r.stakes));
                    }),
                _miniBtn(
                    key: Key('rejectResBtn_${r.id}'),
                    label: '✕',
                    danger: true,
                    onTap: () => unawaited(ref.read(reservationsRepositoryProvider).cancel(r.id))),
              ],
            ),
            const SizedBox(height: PsSpacing.s2),
            Text(l10n.reservedHint,
                style: TextStyle(
                    fontSize: PsType.caption,
                    fontStyle: FontStyle.italic,
                    color: PsColors.textFaint)),
          ],
        ),
      ),
    );
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
    PsSheet.show<void>(context, child: _SeatPickerSheet(clubId: clubId, table: t, seat: seat));
  }

  /// Add a walk-in to the shared waitlist by typed name (mockup `+ Add`).
  /// Registered-user search is out of scope: rules forbid Pit Bosses reading
  /// the full users collection.
  void _addToWaitlist(BuildContext context, WidgetRef ref, PokerTable t) {
    final c = TextEditingController();
    final l10n = AppL10n.of(context);
    PsSheet.show<void>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.waitlistTitle,
              style: const TextStyle(
                  fontSize: PsType.headline, fontWeight: PsType.weightBold, color: PsColors.text)),
          const SizedBox(height: PsSpacing.s3),
          PsTextField(controller: c, hintText: l10n.searchUsersHint, autofocus: true),
          const SizedBox(height: PsSpacing.s4),
          PsButton(
            key: const Key('addWaitlistSaveBtn'),
            label: '+ ${l10n.addLabel}',
            onPressed: () {
              final name = c.text.trim();
              if (name.isEmpty) return;
              final nav = Navigator.of(context);
              unawaited(ref.read(waitlistRepositoryProvider).join(
                    clubId: clubId,
                    playerUid: 'walk-in:${DateTime.now().microsecondsSinceEpoch}',
                    playerName: name,
                    stakes: t.stakes,
                  ));
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

/// Live count-up session timer (mockup `.seated-item .tm`): ticks every second
/// showing `h:mm:ss` since [start], in accent-secondary, turning status-open
/// once the session passes the 8-hour warning window.
class _ElapsedTimer extends StatefulWidget {
  const _ElapsedTimer({required this.start});
  final DateTime start;

  @override
  State<_ElapsedTimer> createState() => _ElapsedTimerState();
}

class _ElapsedTimerState extends State<_ElapsedTimer> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = DateTime.now().difference(widget.start);
    final warn = d > _sessionWarn;
    final h = d.inHours, m = d.inMinutes % 60, s = d.inSeconds % 60;
    return Text(
      '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}',
      style: TextStyle(
        fontWeight: PsType.weightBlack,
        color: warn ? PsColors.statusOpen : PsColors.accentSecondary,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

/// Seat-a-player sheet (mockup smart search): the top waiting player ("Call #1"),
/// registered players matched by name/phone, or a walk-in using the typed name.
class _SeatPickerSheet extends ConsumerStatefulWidget {
  const _SeatPickerSheet({required this.clubId, required this.table, required this.seat});
  final String clubId;
  final PokerTable table;
  final int seat;

  @override
  ConsumerState<_SeatPickerSheet> createState() => _SeatPickerSheetState();
}

class _SeatPickerSheetState extends ConsumerState<_SeatPickerSheet> {
  final _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  void _seat(WaitlistEntry e) {
    final nav = Navigator.of(context);
    unawaited(ref.read(waitlistRepositoryProvider)
        .seat(entry: e, tableId: widget.table.id, seatNumber: widget.seat));
    nav.pop();
  }

  void _seatUser(AppUser u) {
    final nav = Navigator.of(context);
    unawaited(ref.read(sessionsRepositoryProvider).seatPlayer(
          clubId: widget.clubId, tableId: widget.table.id, seatNumber: widget.seat,
          stakes: widget.table.stakes, playerUid: u.uid,
          playerName: '${u.firstName} ${u.lastName}'.trim()));
    nav.pop();
  }

  void _walkIn() {
    final nav = Navigator.of(context);
    final name = _q.text.trim().isEmpty ? AppL10n.of(context).walkInLabel : _q.text.trim();
    unawaited(ref.read(sessionsRepositoryProvider).seatWalkIn(
          clubId: widget.clubId, tableId: widget.table.id, seatNumber: widget.seat,
          stakes: widget.table.stakes, playerName: name));
    nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final query = _q.text.trim().toLowerCase();
    final waiting = (ref.watch(clubWaitlistProvider(widget.clubId)).valueOrNull ?? const <WaitlistEntry>[])
        .where((e) => e.stakes.label == widget.table.stakes.label)
        .where((e) => query.isEmpty || e.playerName.toLowerCase().contains(query))
        .toList();
    // Registered players matched by name / phone (rules let Pit Bosses read users).
    final registered = (ref.watch(allUsersProvider).valueOrNull ?? const <AppUser>[])
        .where((u) => u.role == AppRole.player)
        .where((u) => query.isEmpty ||
            '${u.firstName} ${u.lastName}'.toLowerCase().contains(query) ||
            u.phone.toLowerCase().contains(query))
        .take(6)
        .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('${l10n.seatWhoTitle} · #${widget.seat}',
            style: const TextStyle(
                fontSize: PsType.headline, fontWeight: PsType.weightBold, color: PsColors.text)),
        const SizedBox(height: PsSpacing.s3),
        PsTextField(
          controller: _q,
          hintText: l10n.searchUsersHint,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: PsSpacing.s3),
        // Waiting players (top one is "Call #1").
        for (var i = 0; i < waiting.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: PsSpacing.s2),
            child: PsCard(
              key: Key('pick_${waiting[i].id}'),
              onTap: () => _seat(waiting[i]),
              child: PsListTile(
                leading: i == 0 && query.isEmpty
                    ? const Icon(Icons.campaign, size: 20, color: PsColors.accentPrimary)
                    : null,
                title: waiting[i].playerName.isEmpty ? '—' : waiting[i].playerName,
                subtitle: i == 0 && query.isEmpty ? '${l10n.callAction} #1' : waiting[i].stakes.label,
              ),
            ),
          ),
        // Registered players matched by the search.
        for (final u in registered)
          Padding(
            padding: const EdgeInsets.only(bottom: PsSpacing.s2),
            child: PsCard(
              key: Key('regPick_${u.uid}'),
              onTap: () => _seatUser(u),
              child: PsListTile(
                leading: PsAvatar(initials: _initials(u), size: 32),
                title: '${u.firstName} ${u.lastName}'.trim().isEmpty
                    ? '—'
                    : '${u.firstName} ${u.lastName}'.trim(),
                subtitle: u.phone,
              ),
            ),
          ),
        PsButton(
          key: const Key('walkInBtn'),
          label: _q.text.trim().isEmpty ? l10n.walkInLabel : '${l10n.walkInLabel}: ${_q.text.trim()}',
          icon: Icons.directions_walk,
          variant: PsButtonVariant.secondary,
          onPressed: _walkIn,
        ),
      ],
    );
  }

  static String _initials(AppUser u) {
    final f = u.firstName.trim();
    final l = u.lastName.trim();
    final a = f.isNotEmpty ? f[0] : '';
    final b = l.isNotEmpty ? l[0] : (f.length >= 2 ? f[1] : '');
    final s = (a + b).toUpperCase();
    return s.isEmpty ? '?' : s;
  }
}

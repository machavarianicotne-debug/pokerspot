import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/features/auth/domain/app_user.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';
import 'package:pokerspot/features/floor/domain/floor_repositories.dart';
import 'package:pokerspot/features/floor/domain/poker_table.dart';
import 'package:pokerspot/features/floor/domain/reservation.dart';
import 'package:pokerspot/features/floor/domain/session.dart';
import 'package:pokerspot/features/floor/domain/stakes.dart';
import 'package:pokerspot/features/floor/domain/waitlist_entry.dart';
import 'package:pokerspot/features/floor/presentation/providers.dart';
import 'package:pokerspot/shared/widgets/ps_avatar.dart';
import 'package:pokerspot/shared/widgets/ps_button.dart';
import 'package:pokerspot/shared/widgets/ps_card.dart';
import 'package:pokerspot/shared/widgets/ps_countdown.dart';
import 'package:pokerspot/shared/widgets/ps_filter_pill.dart';
import 'package:pokerspot/shared/widgets/ps_list_tile.dart';
import 'package:pokerspot/shared/widgets/ps_overline.dart';
import 'package:pokerspot/shared/widgets/ps_scaffold.dart';
import 'package:pokerspot/shared/widgets/ps_seat_map.dart';
import 'package:pokerspot/shared/widgets/ps_sheet.dart';
import 'package:pokerspot/shared/widgets/ps_text_field.dart';

/// A called/reservation hold lasts 30 minutes (mirrors the mockup).
/// A called waitlist entry is held for 10 minutes (matches the seat hold).
const _holdWindow = Duration(minutes: 10);

const _sessionWarn = Duration(hours: 8);

/// Run a Firestore write and surface any error (e.g. permission-denied) as a
/// SnackBar instead of letting an unawaited future fail silently — otherwise a
/// denied seat/hold write just looks like "nothing happened".
Future<void> _surface(BuildContext context, Future<void> Function() run) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await run();
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text('⚠ $e'), duration: const Duration(seconds: 6)),
    );
  }
}

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
              // On a game-detail screen the table set is only ever empty while a
              // stake edit relabels the tables (or the stream is still loading) —
              // never a real "no tables" state — so show a spinner instead of the
              // jarring "no tables yet" message.
              const Expanded(child: Center(child: CircularProgressIndicator()))
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
                      for (final r in reservations)
                        _reservationRow(
                            context, ref, tables, sessions, _firstFreeSeat(tables, sessions), r),
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
                onTap: () => unawaited(_confirmDeleteTable(context, ref, tables, t)),
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
            filledSeats: {for (final e in bySeat.entries) if (e.value.isActive) e.key},
            heldSeats: {for (final e in bySeat.entries) if (e.value.isHeld) e.key},
            warnSeats: {
              for (final e in bySeat.entries)
                if (e.value.isActive && _warn(e.value)) e.key,
            },
            onSeatTap: (seat) {
              final s = bySeat[seat];
              if (s == null) {
                _seatPicker(context, ref, tables, t, seat);
              } else if (s.isHeld) {
                _heldActions(context, ref, s);
              } else {
                _endSession(context, ref, s);
              }
            },
          ),
          // Held seats (red — reserved 30 min / called 10 min) with countdown.
          for (final seat in (bySeat.keys.where((k) => bySeat[k]!.isHeld).toList()..sort()))
            Padding(
              padding: const EdgeInsets.only(top: PsSpacing.s2),
              child: _heldSeatRow(context, ref, seat, bySeat[seat]!),
            ),
          if (bySeat.values.any((s) => s.isActive)) ...[
            const SizedBox(height: PsSpacing.s3),
            Align(
              alignment: Alignment.centerLeft,
              child: PsOverline(
                  '${l10n.seatedLabel} · ${bySeat.values.where((s) => s.isActive).length}'),
            ),
            const SizedBox(height: PsSpacing.s1),
            for (final seat in (bySeat.keys.where((k) => bySeat[k]!.isActive).toList()..sort()))
              _seatedItem(context, ref, seat, bySeat[seat]!),
          ],
          const SizedBox(height: PsSpacing.s3),
          _metaTile(l10n.gameLabel, _gameRowValue(t),
              () => _editVariant(context, ref, tables, t)),
          _metaRow(context, ref, tables, l10n.blindsLabel, '${_fmt(t.stakes.smallBlind)}/${_fmt(t.stakes.bigBlind)}',
              (v) => _editBlinds(context, ref, tables, v)),
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
          String value, void Function(String) onSave) =>
      _metaTile(label, value, () => _editMeta(context, label, value, onSave));

  /// Tappable label/value row used by the blinds/avg/min editors and the game
  /// variant picker (same look, different editor sheet).
  Widget _metaTile(String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
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
                // Call removed — players are auto-notified (notifySeatOpen) when a
                // seat frees; the Pit just seats the next one.
                _miniBtn(
                    key: Key('seatBtn_${waitlist[i].id}'),
                    label: l10n.seatAction,
                    primary: true,
                    onTap: (_heldFor(sessions, waitlist[i].playerUid) == null && firstFree == null)
                        ? null
                        : () => _seatWaitlist(context, ref, waitlist[i], sessions, firstFree)),
                _miniBtn(
                    key: Key('removeWlBtn_${waitlist[i].id}'),
                    label: '✕',
                    danger: true,
                    onTap: () => unawaited(_surface(
                        context, () => ref.read(waitlistRepositoryProvider).cancel(waitlist[i].id)))),
              ],
            ),
          ),
        ),
    ];
  }

  /// True if [uid] already occupies (active) or holds a seat at [tableId]. Used
  /// to stop a player being seated/held twice at the SAME table. Walk-ins have
  /// no uid (empty) so they are never matched — we can't reliably tell them
  /// apart by typed name.
  @visibleForTesting
  static bool seatedAtTable(List<Session> sessions, String uid, String tableId) {
    if (uid.isEmpty) return false;
    for (final s in sessions) {
      if (s.playerUid == uid && s.tableId == tableId && (s.isActive || s.isHeld)) {
        return true;
      }
    }
    return false;
  }

  /// The open held session for [uid] (reserved/called seat), if any.
  static Session? _heldFor(List<Session> sessions, String uid) {
    for (final s in sessions) {
      if (s.playerUid == uid && s.isHeld) return s;
    }
    return null;
  }

  /// Seat a player from their existing held seat (the table-side Seat button).
  /// If the hold came from a waitlist call, also flip that waitlist entry to
  /// seated so its 'called' countdown stops — otherwise the seat goes active but
  /// the waitlist row keeps ticking. Mirrors the waitlist-side Seat button
  /// (_seatWaitlist) so both Seat buttons behave identically.
  @visibleForTesting
  static Future<void> seatFromHeld({
    required SessionsRepository sessionsRepo,
    required WaitlistRepository waitlistRepo,
    required Session held,
    required List<WaitlistEntry> waitlist,
  }) async {
    await sessionsRepo.seatFromHold(held.id);
    for (final e in waitlist) {
      if (e.playerUid == held.playerUid && e.status == WaitlistStatus.called) {
        await waitlistRepo.markSeated(e.id);
        break;
      }
    }
  }

  /// Seat a waiting player: from their held seat if one exists (no double-book),
  /// otherwise straight into the first free seat.
  void _seatWaitlist(BuildContext context, WidgetRef ref, WaitlistEntry e, List<Session> sessions,
      ({String tableId, int seat})? free) {
    final held = _heldFor(sessions, e.playerUid);
    if (held != null) {
      unawaited(_surface(context, () async {
        await ref.read(sessionsRepositoryProvider).seatFromHold(held.id);
        await ref.read(waitlistRepositoryProvider).markSeated(e.id);
      }));
    } else if (free != null && !seatedAtTable(sessions, e.playerUid, free.tableId)) {
      unawaited(_surface(context, () => ref.read(waitlistRepositoryProvider)
          .seat(entry: e, tableId: free.tableId, seatNumber: free.seat)));
    }
  }

  /// First free seat across the game's tables (null when every seat is taken).
  static ({String tableId, int seat})? _firstFreeSeat(
      List<PokerTable> tables, List<Session> sessions) {
    for (final t in tables) {
      final taken = sessions.where((s) => s.tableId == t.id).map((s) => s.seatNumber).toSet();
      for (var n = 1; n <= t.seatCount; n++) {
        if (!taken.contains(n)) return (tableId: t.id, seat: n);
      }
    }
    return null;
  }

  /// Reservation Seat — from a held seat if one exists, otherwise the first free
  /// seat; consume the reservation. Mirrors the waitlist Seat.
  void _seatReservation(BuildContext context, WidgetRef ref, List<Session> sessions, Reservation r,
      ({String tableId, int seat})? free) {
    final held = _heldFor(sessions, r.playerUid);
    final resRepo = ref.read(reservationsRepositoryProvider);
    if (held != null) {
      unawaited(_surface(context, () async {
        await ref.read(sessionsRepositoryProvider).seatFromHold(held.id);
        await resRepo.markArrived(r.id);
      }));
    } else if (free != null && !seatedAtTable(sessions, r.playerUid, free.tableId)) {
      unawaited(_surface(context, () async {
        await ref.read(sessionsRepositoryProvider).seatPlayer(
            clubId: clubId, tableId: free.tableId, seatNumber: free.seat,
            stakes: r.stakes, playerUid: r.playerUid, playerName: r.playerName);
        await resRepo.markArrived(r.id);
      }));
    }
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

  /// One held reservation, shown like a waitlist row: name + live countdown, and
  /// Call / Seat (the Pit handles it exactly like a waiting player) / reject.
  Widget _reservationRow(BuildContext context, WidgetRef ref, List<PokerTable> tables,
      List<Session> sessions, ({String tableId, int seat})? free, Reservation r) {
    final l10n = AppL10n.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: PsSpacing.s2),
      child: PsCard(
        key: Key('resRow_${r.id}'),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(r.playerName.isEmpty ? '—' : r.playerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: PsType.body,
                          fontWeight: PsType.weightBold,
                          color: PsColors.text)),
                  if (r.heldUntil != null)
                    Row(
                      children: [
                        Text('${l10n.reservedBadge} · ',
                            style: const TextStyle(
                                fontSize: PsType.caption,
                                fontWeight: PsType.weightBlack,
                                color: PsColors.accentSecondary)),
                        PsCountdown(
                            deadline: r.heldUntil!,
                            style: const TextStyle(
                                fontSize: PsType.caption, fontWeight: PsType.weightBlack)),
                      ],
                    ),
                ],
              ),
            ),
            _miniBtn(
                key: Key('resSeatBtn_${r.id}'),
                label: l10n.seatAction,
                primary: true,
                onTap: () => _seatReservation(context, ref, sessions, r, free)),
            _miniBtn(
                key: Key('rejectResBtn_${r.id}'),
                label: '✕',
                danger: true,
                onTap: () => unawaited(ref.read(reservationsRepositoryProvider).cancel(r.id))),
          ],
        ),
      ),
    );
  }

  // ---- actions ------------------------------------------------------------

  Future<void> _editBlinds(
      BuildContext context, WidgetRef ref, List<PokerTable> tables, String v) async {
    final parts = v.split('/');
    final sb = parts.isNotEmpty ? num.tryParse(parts[0].trim()) : null;
    final bb = parts.length > 1 ? num.tryParse(parts[1].trim()) : null;
    if (sb == null || bb == null || tables.isEmpty) return;
    final newLabel = tables.first.stakes.copyWith(smallBlind: sb, bigBlind: bb).label;
    final nav = Navigator.of(context);
    for (final t in tables) {
      await ref.read(tablesRepositoryProvider)
          .updateTable(t.copyWith(stakes: t.stakes.copyWith(smallBlind: sb, bigBlind: bb)));
    }
    _reopenWithLabel(nav, newLabel);
  }

  void _updateAll(WidgetRef ref, List<PokerTable> tables, {num? avg, num? min}) {
    for (final t in tables) {
      unawaited(ref.read(tablesRepositoryProvider)
          .updateTable(t.copyWith(avgStack: avg ?? t.avgStack, minBuyIn: min ?? t.minBuyIn)));
    }
  }

  /// A blinds/variant edit changes the stake LABEL — this screen's identity — so
  /// the relabeled tables stop matching [stakeLabel] and the screen would fall to
  /// "no tables yet". Re-open the screen on the new label so it follows the game.
  void _reopenWithLabel(NavigatorState nav, String newLabel) {
    if (newLabel == stakeLabel) return;
    nav.pushReplacement(MaterialPageRoute<void>(
        builder: (_) => GameDetailScreen(clubId: clubId, stakeLabel: newLabel)));
  }

  /// Confirm before removing a table. Deleting the game's last table empties this
  /// screen, so leave it afterwards (it would otherwise sit on the spinner).
  Future<void> _confirmDeleteTable(
      BuildContext context, WidgetRef ref, List<PokerTable> tables, PokerTable t) async {
    final l10n = AppL10n.of(context);
    final nav = Navigator.of(context);
    final wasLast = tables.length <= 1;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteTable),
        content: Text(l10n.deleteTableConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.cancelWaitlist)),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(l10n.deleteTable)),
        ],
      ),
    );
    if (ok != true) return;
    // When this is the stake's LAST table, its shared waitlist is now orphaned —
    // cancel those entries so players stop showing as "in the waitlist".
    final waitlistToCancel = wasLast
        ? (ref.read(clubWaitlistProvider(clubId)).valueOrNull ?? const <WaitlistEntry>[])
            .where((e) => e.stakes.label == stakeLabel)
            .toList()
        : const <WaitlistEntry>[];
    await deleteTableAndEndSessions(
      tablesRepo: ref.read(tablesRepositoryProvider),
      sessionsRepo: ref.read(sessionsRepositoryProvider),
      waitlistRepo: ref.read(waitlistRepositoryProvider),
      sessions: ref.read(clubSessionsProvider(clubId)).valueOrNull ?? const <Session>[],
      waitlistToCancel: waitlistToCancel,
      clubId: clubId,
      tableId: t.id,
    );
    if (wasLast) nav.pop();
  }

  /// End the table's open sessions (players stop showing as "playing"), cancel
  /// the now-orphaned waitlist entries (passed in when this was the stake's last
  /// table), then delete the table. Sessions/waitlist are passed in from the
  /// club providers — which the Pit Boss may read — rather than queried inside
  /// the repo, where Firestore rules reject an unconstrained query.
  @visibleForTesting
  static Future<void> deleteTableAndEndSessions({
    required TablesRepository tablesRepo,
    required SessionsRepository sessionsRepo,
    required WaitlistRepository waitlistRepo,
    required List<Session> sessions,
    required List<WaitlistEntry> waitlistToCancel,
    required String clubId,
    required String tableId,
  }) async {
    for (final s in sessions.where((s) => s.tableId == tableId && (s.isActive || s.isHeld))) {
      await sessionsRepo.end(s.id);
    }
    for (final e in waitlistToCancel) {
      await waitlistRepo.cancel(e.id);
    }
    await tablesRepo.deleteTable(clubId: clubId, tableId: tableId);
  }

  /// Row value for the game: just the variant, or "NLH/PLO · 2×PLO5" once the
  /// mixed-game Omaha config is set.
  String _gameRowValue(PokerTable t) {
    // NLH with Omaha mixed in shows e.g. "NLH · x2PLO5"; the NLH/PLO and NLH/PLO5
    // labels already carry their Omaha flavour, so they need no suffix.
    final suffix = t.omahaSuffix;
    return suffix.isEmpty ? t.stakes.variant.label : '${t.stakes.variant.label} · $suffix';
  }

  /// PLO / PLO5 chooser pills (shared by the NLH and NLH/PLO Omaha config).
  static Widget _omahaVariantPills(GameVariant selected, ValueChanged<GameVariant> onPick) => Wrap(
        spacing: PsSpacing.s2,
        runSpacing: PsSpacing.s2,
        children: [
          for (final v in const [GameVariant.plo, GameVariant.plo5])
            PsFilterPill(label: v.label, active: selected == v, onTap: () => onPick(v)),
        ],
      );

  /// Change the game variant (NLH / PLO / PLO5 / PLO6 / NLH-PLO) for every
  /// same-stake table of this game — mirrors like blinds/avg/min. For NLH/PLO,
  /// also picks the Omaha-per-orbit count (1/2) and, once set, the Omaha variant.
  void _editVariant(BuildContext context, WidgetRef ref, List<PokerTable> tables, PokerTable t) {
    final l10n = AppL10n.of(context);
    final variant = t.stakes.variant;
    // NLH/PLO5 normalises onto the NLH/PLO pill; its Omaha sub-choice carries PLO5.
    var sel = variant == GameVariant.nlhPlo5 ? GameVariant.nlhPlo : variant;
    int? perCircle = t.omahaPerCircle;
    var omahaVar = variant == GameVariant.nlhPlo5
        ? GameVariant.plo5
        : variant == GameVariant.nlhPlo
            ? GameVariant.plo
            : (t.omahaVariant ?? GameVariant.plo);
    PsSheet.show<void>(
      context,
      child: StatefulBuilder(
        builder: (ctx, setSheet) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.gameLabel,
                style: const TextStyle(
                    fontSize: PsType.headline, fontWeight: PsType.weightBold, color: PsColors.text)),
            const SizedBox(height: PsSpacing.s3),
            Wrap(
              spacing: PsSpacing.s2,
              runSpacing: PsSpacing.s2,
              children: [
                for (final v in pickerGameVariants)
                  PsFilterPill(
                    label: v.label,
                    active: sel == v,
                    onTap: () => setSheet(() => sel = v),
                  ),
              ],
            ),
            // NLH: optional Omaha mixed in — pick how many per circle (1/2), then
            // which Omaha. NLH/PLO: just pick the Omaha variant (always present).
            if (sel == GameVariant.nlh) ...[
              const SizedBox(height: PsSpacing.s4),
              const PsOverline('OMAHA / CIRCLE'),
              const SizedBox(height: PsSpacing.s2),
              Wrap(
                spacing: PsSpacing.s2,
                runSpacing: PsSpacing.s2,
                children: [
                  for (final n in const [1, 2])
                    PsFilterPill(
                      label: '$n',
                      active: perCircle == n,
                      // Tap the active count again to clear it (plain NLH, no Omaha).
                      onTap: () => setSheet(() => perCircle = perCircle == n ? null : n),
                    ),
                ],
              ),
              if (perCircle != null) ...[
                const SizedBox(height: PsSpacing.s4),
                const PsOverline('OMAHA'),
                const SizedBox(height: PsSpacing.s2),
                _omahaVariantPills(omahaVar, (v) => setSheet(() => omahaVar = v)),
              ],
            ] else if (sel == GameVariant.nlhPlo) ...[
              const SizedBox(height: PsSpacing.s4),
              const PsOverline('OMAHA'),
              const SizedBox(height: PsSpacing.s2),
              _omahaVariantPills(omahaVar, (v) => setSheet(() => omahaVar = v)),
            ],
            const SizedBox(height: PsSpacing.s4),
            PsButton(
              key: const Key('saveVariantBtn'),
              label: l10n.saveLabel,
              onPressed: () async {
                // Resolve the stored variant + Omaha fields:
                //  NLH     → stays NLH; keeps count + Omaha only when a count is set
                //  NLH/PLO → NLH/PLO (PLO) or NLH/PLO5 (PLO5) per the sub-choice,
                //            so the game name itself becomes NLH/PLO vs NLH/PLO5
                //  others  → as picked, no Omaha config
                // Build the table directly because copyWith can't null these out.
                var finalVariant = sel;
                int? per;
                GameVariant? ov;
                if (sel == GameVariant.nlh && perCircle != null) {
                  per = perCircle;
                  ov = omahaVar;
                } else if (sel == GameVariant.nlhPlo) {
                  finalVariant =
                      omahaVar == GameVariant.plo5 ? GameVariant.nlhPlo5 : GameVariant.nlhPlo;
                }
                final newLabel = tables.first.stakes.copyWith(variant: finalVariant).label;
                final nav = Navigator.of(ctx);
                for (final tt in tables) {
                  await ref.read(tablesRepositoryProvider).updateTable(PokerTable(
                        id: tt.id,
                        clubId: tt.clubId,
                        number: tt.number,
                        stakes: tt.stakes.copyWith(variant: finalVariant),
                        seatCount: tt.seatCount,
                        open: tt.open,
                        avgStack: tt.avgStack,
                        minBuyIn: tt.minBuyIn,
                        omahaPerCircle: per,
                        omahaVariant: ov,
                      ));
                }
                nav.pop(); // close the sheet
                _reopenWithLabel(nav, newLabel);
              },
            ),
          ],
        ),
      ),
    );
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

  /// A held seat (reserved 30 min / called 10 min): holder + live countdown +
  /// Seat (the player arrived) / release.
  Widget _heldSeatRow(BuildContext context, WidgetRef ref, int seat, Session s) {
    final l10n = AppL10n.of(context);
    return PsCard(
      key: Key('heldRow_${s.id}'),
      accentRail: PsColors.statusLive,
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: PsColors.statusLive.withValues(alpha: 0.16),
            ),
            child: Text('$seat',
                style: const TextStyle(
                    fontSize: PsType.micro, fontWeight: PsType.weightBlack, color: PsColors.statusLive)),
          ),
          const SizedBox(width: PsSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(s.playerName.isEmpty ? '—' : s.playerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: PsType.body, fontWeight: PsType.weightBold, color: PsColors.text)),
                Row(
                  children: [
                    Text(
                        '${s.holdKind == HoldKind.called ? l10n.callAction : l10n.reservedBadge} · ',
                        style: const TextStyle(
                            fontSize: PsType.caption,
                            fontWeight: PsType.weightBlack,
                            color: PsColors.statusLive)),
                    if (s.heldUntil != null)
                      PsCountdown(
                          deadline: s.heldUntil!,
                          style: const TextStyle(
                              fontSize: PsType.caption, fontWeight: PsType.weightBlack)),
                  ],
                ),
              ],
            ),
          ),
          _miniBtn(
              key: Key('seatHeldBtn_${s.id}'),
              label: l10n.seatAction,
              primary: true,
              onTap: () => unawaited(_surface(
                  context,
                  () => seatFromHeld(
                        sessionsRepo: ref.read(sessionsRepositoryProvider),
                        waitlistRepo: ref.read(waitlistRepositoryProvider),
                        held: s,
                        waitlist: ref.read(clubWaitlistProvider(clubId)).valueOrNull ??
                            const [],
                      )))),
          _miniBtn(
              key: Key('relHeldBtn_${s.id}'),
              label: '✕',
              danger: true,
              onTap: () => unawaited(
                  _surface(context, () => ref.read(sessionsRepositoryProvider).releaseHold(s.id)))),
        ],
      ),
    );
  }

  void _heldActions(BuildContext context, WidgetRef ref, Session s) {
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
            key: Key('seatHeldSheetBtn_${s.id}'),
            label: l10n.seatAction,
            onPressed: () {
              final nav = Navigator.of(context);
              unawaited(_surface(
                  context,
                  () => seatFromHeld(
                        sessionsRepo: ref.read(sessionsRepositoryProvider),
                        waitlistRepo: ref.read(waitlistRepositoryProvider),
                        held: s,
                        waitlist: ref.read(clubWaitlistProvider(clubId)).valueOrNull ??
                            const [],
                      )));
              nav.pop();
            },
          ),
          const SizedBox(height: PsSpacing.s2),
          PsButton(
            key: Key('relHeldSheetBtn_${s.id}'),
            label: l10n.cancelWaitlist,
            variant: PsButtonVariant.secondary,
            onPressed: () {
              final nav = Navigator.of(context);
              unawaited(
                  _surface(context, () => ref.read(sessionsRepositoryProvider).releaseHold(s.id)));
              nav.pop();
            },
          ),
        ],
      ),
    );
  }

  /// Add a walk-in to the shared waitlist by typed name (mockup `+ Add`).
  /// Registered-user search is out of scope: rules forbid Pit Bosses reading
  /// the full users collection.
  void _addToWaitlist(BuildContext context, WidgetRef ref, PokerTable t) {
    PsSheet.show<void>(context, child: _AddToWaitlistSheet(clubId: clubId, stakes: t.stakes));
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
              unawaited(_surface(context, () => ref.read(sessionsRepositoryProvider).end(s.id)));
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

  /// Already-seated players are filtered out of the list, but guard the action
  /// too (defense in depth) so a stale tap can't double-seat at this table.
  bool _blockedAtTable(String uid) {
    final sessions = ref.read(clubSessionsProvider(widget.clubId)).valueOrNull ?? const <Session>[];
    return GameDetailScreen.seatedAtTable(sessions, uid, widget.table.id);
  }

  void _seat(WaitlistEntry e) {
    if (_blockedAtTable(e.playerUid)) return;
    final nav = Navigator.of(context);
    unawaited(_surface(context, () => ref.read(waitlistRepositoryProvider)
        .seat(entry: e, tableId: widget.table.id, seatNumber: widget.seat)));
    nav.pop();
  }

  void _seatUser(AppUser u) {
    if (_blockedAtTable(u.uid)) return;
    final nav = Navigator.of(context);
    unawaited(_surface(context, () => ref.read(sessionsRepositoryProvider).seatPlayer(
          clubId: widget.clubId, tableId: widget.table.id, seatNumber: widget.seat,
          stakes: widget.table.stakes, playerUid: u.uid,
          playerName: '${u.firstName} ${u.lastName}'.trim())));
    nav.pop();
  }

  void _walkIn() {
    final nav = Navigator.of(context);
    final name = _q.text.trim().isEmpty ? AppL10n.of(context).walkInLabel : _q.text.trim();
    unawaited(_surface(context, () => ref.read(sessionsRepositoryProvider).seatWalkIn(
          clubId: widget.clubId, tableId: widget.table.id, seatNumber: widget.seat,
          stakes: widget.table.stakes, playerName: name)));
    nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final query = _q.text.trim().toLowerCase();
    // A player already seated/held at THIS table can't be seated again — drop
    // them from both lists so Pit Boss can't double-seat the same table.
    final sessions = ref.watch(clubSessionsProvider(widget.clubId)).valueOrNull ?? const <Session>[];
    final waiting = (ref.watch(clubWaitlistProvider(widget.clubId)).valueOrNull ?? const <WaitlistEntry>[])
        .where((e) => e.stakes.label == widget.table.stakes.label)
        .where((e) => query.isEmpty || e.playerName.toLowerCase().contains(query))
        .where((e) => !GameDetailScreen.seatedAtTable(sessions, e.playerUid, widget.table.id))
        .toList();
    // Registered players matched by name / phone (rules let Pit Bosses read users).
    final registered = (ref.watch(allUsersProvider).valueOrNull ?? const <AppUser>[])
        .where((u) => u.role == AppRole.player)
        .where((u) => query.isEmpty ||
            '${u.firstName} ${u.lastName}'.toLowerCase().contains(query) ||
            u.phone.toLowerCase().contains(query))
        .where((u) => !GameDetailScreen.seatedAtTable(sessions, u.uid, widget.table.id))
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

/// Add-to-waitlist sheet: search registered players to add to the stake's
/// waitlist, or add a walk-in by typed name (mockup `+ Add`).
class _AddToWaitlistSheet extends ConsumerStatefulWidget {
  const _AddToWaitlistSheet({required this.clubId, required this.stakes});
  final String clubId;
  final Stakes stakes;

  @override
  ConsumerState<_AddToWaitlistSheet> createState() => _AddToWaitlistSheetState();
}

class _AddToWaitlistSheetState extends ConsumerState<_AddToWaitlistSheet> {
  final _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  void _join(String playerUid, String name) {
    final nav = Navigator.of(context);
    unawaited(_surface(context, () => ref.read(waitlistRepositoryProvider).join(
          clubId: widget.clubId, playerUid: playerUid, playerName: name, stakes: widget.stakes)));
    nav.pop();
  }

  static String _initials(AppUser u) {
    final a = u.firstName.trim().isNotEmpty ? u.firstName.trim()[0] : '';
    final b = u.lastName.trim().isNotEmpty ? u.lastName.trim()[0] : '';
    final s = (a + b).toUpperCase();
    return s.isEmpty ? '?' : s;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final query = _q.text.trim().toLowerCase();
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
        Text('${l10n.waitlistTitle} · ${widget.stakes.label}',
            style: const TextStyle(
                fontSize: PsType.headline, fontWeight: PsType.weightBold, color: PsColors.text)),
        const SizedBox(height: PsSpacing.s3),
        PsTextField(controller: _q, hintText: l10n.searchUsersHint, onChanged: (_) => setState(() {})),
        const SizedBox(height: PsSpacing.s3),
        for (final u in registered)
          Padding(
            padding: const EdgeInsets.only(bottom: PsSpacing.s2),
            child: PsCard(
              key: Key('wlAddUser_${u.uid}'),
              onTap: () => _join(u.uid, '${u.firstName} ${u.lastName}'.trim()),
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
          key: const Key('addWalkInWlBtn'),
          label: _q.text.trim().isEmpty ? l10n.walkInLabel : '${l10n.walkInLabel}: ${_q.text.trim()}',
          icon: Icons.directions_walk,
          variant: PsButtonVariant.secondary,
          onPressed: () => _join(
              'walk-in:${DateTime.now().microsecondsSinceEpoch}',
              _q.text.trim().isEmpty ? l10n.walkInLabel : _q.text.trim()),
        ),
      ],
    );
  }
}

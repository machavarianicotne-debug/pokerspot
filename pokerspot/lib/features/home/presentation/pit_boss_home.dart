import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';
import 'package:pokerspot/features/floor/domain/poker_table.dart';
import 'package:pokerspot/features/floor/domain/session.dart';
import 'package:pokerspot/features/floor/domain/waitlist_entry.dart';
import 'package:pokerspot/features/floor/presentation/providers.dart';
import 'package:pokerspot/shared/widgets/ps_avatar.dart';
import 'package:pokerspot/shared/widgets/ps_button.dart';
import 'package:pokerspot/shared/widgets/ps_card.dart';
import 'package:pokerspot/shared/widgets/ps_glass_nav.dart';
import 'package:pokerspot/shared/widgets/ps_list_tile.dart';
import 'package:pokerspot/shared/widgets/ps_overline.dart';
import 'package:pokerspot/shared/widgets/ps_scaffold.dart';
import 'package:pokerspot/shared/widgets/ps_sheet.dart';

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    final p = parts.first;
    return (p.length >= 2 ? p.substring(0, 2) : p).toUpperCase();
  }
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

/// A round glass sign-out affordance for the nav action slot.
class _SignOutAction extends ConsumerWidget {
  const _SignOutAction();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    return Semantics(
      button: true,
      label: l10n.signOut,
      child: GestureDetector(
        onTap: () => ref.read(authRepositoryProvider).signOut(),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(PsSpacing.s1),
          child: Icon(Icons.logout, size: 22, color: PsColors.textMuted),
        ),
      ),
    );
  }
}

/// Pit Boss home: the live waitlist for the staff member's club
/// (`currentUser.clubId`) on top, the seated sessions below. Call moves an
/// entry waiting -> called; Seat creates a Session and frees the entry.
class PitBossHome extends ConsumerWidget {
  const PitBossHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final clubId = ref.watch(currentUserProvider).valueOrNull?.clubId;
    return PsScaffold(
      body: SafeArea(
        child: Column(
          children: [
            PsGlassNav(
              leading: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PsOverline(l10n.pitBossHome),
                  const SizedBox(height: 2),
                  Text(
                    l10n.waitlistTitle,
                    style: const TextStyle(
                      fontSize: PsType.title,
                      fontWeight: PsType.weightBlack,
                      letterSpacing: PsType.trackingSnug,
                      color: PsColors.text,
                    ),
                  ),
                ],
              ),
              actions: const [_SignOutAction()],
            ),
            Expanded(
              child: clubId == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(PsSpacing.s5),
                        child: Text(l10n.noClubAssigned,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: PsColors.textMuted, fontSize: PsType.body)),
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(child: _PitBossWaitlist(clubId: clubId)),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                              PsSpacing.s5, PsSpacing.s2, PsSpacing.s5, PsSpacing.s1),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: PsOverline(l10n.seatedTitle),
                          ),
                        ),
                        Expanded(child: _SessionsList(clubId: clubId)),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PitBossWaitlist extends ConsumerWidget {
  const _PitBossWaitlist({required this.clubId});
  final String clubId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final async = ref.watch(clubWaitlistProvider(clubId));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator(color: PsColors.accentPrimary)),
      error: (e, _) =>
          Center(child: Text('$e', style: const TextStyle(color: PsColors.statusLive))),
      data: (entries) {
        if (entries.isEmpty) {
          return Center(
            child: Text(l10n.waitlistEmpty,
                style: TextStyle(color: PsColors.textMuted, fontSize: PsType.body)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(PsSpacing.s4),
          itemCount: entries.length,
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.only(bottom: PsSpacing.s3),
            child: _WaitlistRow(entry: entries[i]),
          ),
        );
      },
    );
  }
}

String _waited(WaitlistEntry e) {
  final c = e.createdAt;
  if (c == null) return '';
  return ' · ${DateTime.now().difference(c).inMinutes}m';
}

class _WaitlistRow extends ConsumerWidget {
  const _WaitlistRow({required this.entry});
  final WaitlistEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final called = entry.status == WaitlistStatus.called;
    return PsCard(
      key: Key('wlRow_${entry.id}'),
      accentRail: called ? PsColors.accentPrimary : PsColors.accentSecondary,
      child: PsListTile(
        leading: PsAvatar(initials: _initials(entry.playerName)),
        title: entry.playerName,
        subtitle: '${entry.stakes.label}${_waited(entry)}',
        trailing: called
            ? PsButton(
                key: Key('seatBtn_${entry.id}'),
                label: l10n.seatAction,
                onPressed: () => unawaited(
                  PsSheet.show<void>(context, child: _SeatPickerSheet(entry: entry)),
                ),
              )
            : PsButton(
                key: Key('callBtn_${entry.id}'),
                label: l10n.callAction,
                onPressed: () => unawaited(ref.read(waitlistRepositoryProvider).call(entry.id)),
              ),
      ),
    );
  }
}

/// Pick a table + seat number to seat a called player.
class _SeatPickerSheet extends ConsumerWidget {
  const _SeatPickerSheet({required this.entry});
  final WaitlistEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final tables = ref.watch(tablesProvider(entry.clubId)).valueOrNull ?? const <PokerTable>[];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.chooseTable,
          style: const TextStyle(
            fontSize: PsType.headline,
            fontWeight: PsType.weightBold,
            color: PsColors.text,
          ),
        ),
        const SizedBox(height: PsSpacing.s3),
        if (tables.isEmpty)
          Text(l10n.noStakesYet, style: TextStyle(color: PsColors.textMuted))
        else
          for (final t in tables) ...[
            Padding(
              padding: const EdgeInsets.only(top: PsSpacing.s3, bottom: PsSpacing.s2),
              child: Text(
                '${l10n.tableLabel} ${t.number} · ${t.stakes.label}',
                style: const TextStyle(
                  fontSize: PsType.subhead,
                  fontWeight: PsType.weightBold,
                  color: PsColors.text,
                ),
              ),
            ),
            Wrap(
              spacing: PsSpacing.s2,
              runSpacing: PsSpacing.s2,
              children: [
                for (int seat = 1; seat <= t.seatCount; seat++)
                  _SeatChip(
                    seat: seat,
                    tableId: t.id,
                    onTap: () async {
                      final navigator = Navigator.of(context);
                      await ref.read(waitlistRepositoryProvider).seat(
                            entry: entry,
                            tableId: t.id,
                            seatNumber: seat,
                          );
                      navigator.pop();
                    },
                  ),
              ],
            ),
          ],
      ],
    );
  }
}

class _SeatChip extends StatelessWidget {
  const _SeatChip({required this.seat, required this.tableId, required this.onTap});
  final int seat;
  final String tableId;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: Key('seat_${tableId}_$seat'),
      onTap: () => unawaited(onTap()),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: PsColors.glassThin,
          borderRadius: BorderRadius.circular(PsRadii.md),
          border: Border.all(color: PsColors.glassBorder),
        ),
        child: Text(
          '$seat',
          style: const TextStyle(
            fontSize: PsType.body,
            fontWeight: PsType.weightBold,
            color: PsColors.text,
          ),
        ),
      ),
    );
  }
}

class _SessionsList extends ConsumerWidget {
  const _SessionsList({required this.clubId});
  final String clubId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(clubSessionsProvider(clubId)).valueOrNull ?? const <Session>[];
    if (sessions.isEmpty) return const SizedBox.shrink();
    return ListView.builder(
      padding: const EdgeInsets.all(PsSpacing.s4),
      itemCount: sessions.length,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: PsSpacing.s3),
        child: _SessionRow(session: sessions[i]),
      ),
    );
  }
}

class _SessionRow extends ConsumerWidget {
  const _SessionRow({required this.session});
  final Session session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    return PsCard(
      key: Key('sessionRow_${session.id}'),
      accentRail: PsColors.accentPrimary,
      child: PsListTile(
        leading: PsAvatar(initials: _initials(session.playerName)),
        title: '${session.playerName} · #${session.seatNumber}',
        subtitle: session.stakes.label,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ElapsedText(start: session.startedAt),
            const SizedBox(width: PsSpacing.s3),
            GestureDetector(
              key: Key('endBtn_${session.id}'),
              onTap: () => unawaited(ref.read(sessionsRepositoryProvider).end(session.id)),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: PsSpacing.s2, vertical: PsSpacing.s1),
                child: Text(
                  l10n.endSession,
                  style: const TextStyle(
                    fontSize: PsType.subhead,
                    fontWeight: PsType.weightBold,
                    color: PsColors.statusLive,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Live-updating elapsed time since [start] (ticks every second).
class _ElapsedText extends StatefulWidget {
  const _ElapsedText({required this.start});
  final DateTime? start;
  @override
  State<_ElapsedText> createState() => _ElapsedTextState();
}

class _ElapsedTextState extends State<_ElapsedText> {
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
    final s = widget.start;
    final text = s == null ? '—' : _fmt(DateTime.now().difference(s));
    return Text(
      text,
      style: const TextStyle(
        fontSize: PsType.subhead,
        fontWeight: PsType.weightBold,
        color: PsColors.accentSecondary,
      ),
    );
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }
}

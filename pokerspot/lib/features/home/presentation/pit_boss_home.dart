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

/// Pit Boss home: the live waitlist for the staff member's club
/// (`currentUser.clubId`) on top, the seated sessions below. Call moves an
/// entry waiting -> called; Seat creates a Session and frees the entry.
class PitBossHome extends ConsumerWidget {
  const PitBossHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final clubId = ref.watch(currentUserProvider).valueOrNull?.clubId;
    return Scaffold(
      backgroundColor: PsColors.bg0,
      appBar: AppBar(
        backgroundColor: PsColors.bg1,
        title: Text(l10n.waitlistTitle,
            style: const TextStyle(color: PsColors.accentPrimary)),
        actions: [
          TextButton(
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
            child: Text(l10n.signOut, style: TextStyle(color: PsColors.textMuted)),
          ),
        ],
      ),
      body: clubId == null
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
                _SectionHeader(text: l10n.seatedTitle),
                Expanded(child: _SessionsList(clubId: clubId)),
              ],
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        color: PsColors.bg1,
        padding: const EdgeInsets.symmetric(
            horizontal: PsSpacing.s4, vertical: PsSpacing.s2),
        child: Text(text,
            style: TextStyle(color: PsColors.textMuted, fontSize: PsType.subhead)),
      );
}

class _PitBossWaitlist extends ConsumerWidget {
  const _PitBossWaitlist({required this.clubId});
  final String clubId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final async = ref.watch(clubWaitlistProvider(clubId));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
          child: Text('$e', style: const TextStyle(color: PsColors.statusLive))),
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
          itemBuilder: (_, i) => _WaitlistRow(entry: entries[i]),
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
    return Card(
      color: PsColors.bg1,
      margin: const EdgeInsets.only(bottom: PsSpacing.s3),
      child: ListTile(
        key: Key('wlRow_${entry.id}'),
        title: Text(entry.playerName,
            style: const TextStyle(color: PsColors.text, fontWeight: FontWeight.w700)),
        subtitle: Text('${entry.stakes.label}${_waited(entry)}',
            style: TextStyle(color: PsColors.textMuted)),
        trailing: called
            ? FilledButton(
                key: Key('seatBtn_${entry.id}'),
                onPressed: () => unawaited(showModalBottomSheet<void>(
                  context: context,
                  backgroundColor: PsColors.bg1,
                  builder: (_) => _SeatPickerSheet(entry: entry),
                )),
                child: Text(l10n.seatAction),
              )
            : FilledButton(
                key: Key('callBtn_${entry.id}'),
                onPressed: () =>
                    unawaited(ref.read(waitlistRepositoryProvider).call(entry.id)),
                child: Text(l10n.callAction),
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
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(PsSpacing.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.chooseTable,
                style: const TextStyle(
                    color: PsColors.text,
                    fontSize: PsType.headline,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: PsSpacing.s3),
            if (tables.isEmpty)
              Text(l10n.noStakesYet, style: TextStyle(color: PsColors.textMuted))
            else
              for (final t in tables) ...[
                Padding(
                  padding: const EdgeInsets.only(top: PsSpacing.s3),
                  child: Text('${l10n.tableLabel} ${t.number} · ${t.stakes.label}',
                      style: const TextStyle(color: PsColors.text)),
                ),
                Wrap(
                  spacing: PsSpacing.s2,
                  children: [
                    for (int seat = 1; seat <= t.seatCount; seat++)
                      ActionChip(
                        key: Key('seat_${t.id}_$seat'),
                        label: Text('$seat'),
                        onPressed: () async {
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
      itemBuilder: (_, i) => _SessionRow(session: sessions[i]),
    );
  }
}

class _SessionRow extends ConsumerWidget {
  const _SessionRow({required this.session});
  final Session session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    return Card(
      color: PsColors.bg1,
      margin: const EdgeInsets.only(bottom: PsSpacing.s3),
      child: ListTile(
        key: Key('sessionRow_${session.id}'),
        title: Text('${session.playerName} · #${session.seatNumber}',
            style: const TextStyle(color: PsColors.text, fontWeight: FontWeight.w700)),
        subtitle: Text(session.stakes.label,
            style: TextStyle(color: PsColors.textMuted)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ElapsedText(start: session.startedAt),
            const SizedBox(width: PsSpacing.s2),
            TextButton(
              key: Key('endBtn_${session.id}'),
              onPressed: () =>
                  unawaited(ref.read(sessionsRepositoryProvider).end(session.id)),
              child: Text(l10n.endSession,
                  style: const TextStyle(color: PsColors.statusLive)),
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
    return Text(text, style: const TextStyle(color: PsColors.accentSecondary));
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }
}

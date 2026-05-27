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
import 'package:pokerspot/features/floor/presentation/game_detail_screen.dart';
import 'package:pokerspot/features/floor/presentation/new_game_screen.dart';
import 'package:pokerspot/features/tournaments/domain/tournament.dart';
import 'package:pokerspot/features/tournaments/presentation/providers.dart';
import 'package:pokerspot/features/tournaments/presentation/tournament_detail_screen.dart'
    show TournamentDetailScreen, tournamentWhen;
import 'package:pokerspot/features/tournaments/presentation/tournament_editor_screen.dart';
import 'package:pokerspot/shared/widgets/ps_button.dart';
import 'package:pokerspot/shared/widgets/ps_card.dart';
import 'package:pokerspot/shared/widgets/ps_overline.dart';

/// Pit Boss "Tables" tab — the table-centric floor (mockup `pit-boss-live-floor`):
/// numbered table cards with a mini seat row, occupancy and per-stake waiting
/// count. New game / New table actions on top; tap a card → its seat map.
class TablesScreen extends ConsumerWidget {
  const TablesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final clubId = ref.watch(currentUserProvider).valueOrNull?.clubId;
    if (clubId == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(PsSpacing.s5),
          child: Text(l10n.noClubAssigned,
              textAlign: TextAlign.center,
              style: TextStyle(color: PsColors.textMuted, fontSize: PsType.body)),
        ),
      );
    }

    final tablesAsync = ref.watch(tablesProvider(clubId));
    final tables = tablesAsync.valueOrNull ?? const <PokerTable>[];
    final sessions = ref.watch(clubSessionsProvider(clubId)).valueOrNull ?? const <Session>[];
    final waitlist = ref.watch(clubWaitlistProvider(clubId)).valueOrNull ?? const <WaitlistEntry>[];

    // Self-heal: end any open session whose table no longer exists (an orphan from
    // a table deleted before sessions were auto-ended, or any future gap). Only
    // once tables have actually loaded — never during the initial load, when the
    // list is briefly empty — and after the frame so we don't mutate during build.
    if (tablesAsync.hasValue) {
      final ids = tables.map((t) => t.id).toSet();
      final orphans = sessions.where((s) => !ids.contains(s.tableId)).toList();
      if (orphans.isNotEmpty) {
        final repo = ref.read(sessionsRepositoryProvider);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          for (final s in orphans) {
            unawaited(repo.end(s.id));
          }
        });
      }
    }
    // Upcoming tournaments the Pit Boss can tap to edit/delete (keeps just-started
    // ones briefly, like the player club view).
    final tournaments = (ref.watch(clubTournamentsProvider(clubId)).valueOrNull ?? const <Tournament>[])
        .where((t) =>
            t.startAt == null || t.startAt!.isAfter(DateTime.now().subtract(const Duration(hours: 6))))
        .toList();
    int occupied(String tableId) => sessions.where((s) => s.tableId == tableId).length;
    int waiting(String tableId) => waitlist.where((e) => e.tableId == tableId).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(PsSpacing.s4, PsSpacing.s4, PsSpacing.s4, 96),
      children: [
        // New Table is intentionally hidden: New Game now covers every table
        // control (seat count / table number / open state), so a separate
        // single-table editor is redundant. TableEditorSheet stays in the
        // codebase, just no longer wired to a button.
        PsButton(
          key: const Key('newGameBtn'),
          label: l10n.newGame,
          icon: Icons.add,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => NewGameScreen(clubId: clubId)),
          ),
        ),
        const SizedBox(height: PsSpacing.s2),
        PsButton(
          key: const Key('newTournamentBtn'),
          label: l10n.newTournament,
          icon: Icons.emoji_events_outlined,
          variant: PsButtonVariant.secondary,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => TournamentEditorScreen(clubId: clubId)),
          ),
        ),
        const SizedBox(height: PsSpacing.s4),
        // Upcoming tournaments at the TOP — tap to edit / delete.
        if (tournaments.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: PsSpacing.s3),
            child: PsOverline(l10n.upcomingTournaments),
          ),
          for (final t in tournaments)
            Padding(
              padding: const EdgeInsets.only(bottom: PsSpacing.s2),
              child: PsCard(
                key: Key('pbTournamentCard_${t.id}'),
                accentRail: PsColors.accentSecondary,
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => TournamentDetailScreen(tournament: t))),
                child: Row(
                  children: [
                    const Text('🏆', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: PsSpacing.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.name.isEmpty ? tournamentTypeLabel(t.type, l10n) : t.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: PsType.body,
                                  fontWeight: PsType.weightBold,
                                  color: PsColors.text)),
                          const SizedBox(height: 2),
                          Text(tournamentWhen(t),
                              style: const TextStyle(
                                  fontSize: PsType.caption,
                                  fontWeight: PsType.weightBold,
                                  color: PsColors.accentPrimary)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 18, color: PsColors.textFaint),
                  ],
                ),
              ),
            ),
          const SizedBox(height: PsSpacing.s5),
        ],
        if (tables.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: PsSpacing.s8),
            child: Text(l10n.noTablesYet,
                textAlign: TextAlign.center,
                style: TextStyle(color: PsColors.textMuted, fontSize: PsType.body)),
          )
        else
          for (final t in tables)
            Padding(
              padding: const EdgeInsets.only(bottom: PsSpacing.s3),
              child: _TableCard(
                table: t,
                occupied: occupied(t.id),
                waiting: waiting(t.id),
              ),
            ),
      ],
    );
  }
}

class _TableCard extends StatelessWidget {
  const _TableCard({required this.table, required this.occupied, required this.waiting});
  final PokerTable table;
  final int occupied;
  final int waiting;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final full = occupied >= table.seatCount;
    return PsCard(
      key: Key('tableCard_${table.id}'),
      accentRail: table.open ? PsColors.accentPrimary : PsColors.statusClosed,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => GameDetailScreen(clubId: table.clubId, tableId: table.id),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _NumOrb(number: table.number, open: table.open),
              const SizedBox(width: PsSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        table.omahaSuffix.isEmpty
                            ? table.stakes.label
                            : '${table.stakes.label} · ${table.omahaSuffix}',
                        style: const TextStyle(
                            fontSize: PsType.headline,
                            fontWeight: PsType.weightBlack,
                            letterSpacing: PsType.trackingSnug,
                            color: PsColors.text)),
                    const SizedBox(height: 2),
                    Text('${l10n.tableLabel} ${table.number}',
                        style: TextStyle(fontSize: PsType.caption, color: PsColors.textMuted)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: PsColors.textFaint),
            ],
          ),
          const SizedBox(height: PsSpacing.s3),
          Container(height: 1, color: PsColors.glassBorder),
          const SizedBox(height: PsSpacing.s3),
          Row(
            children: [
              _MiniSeats(total: table.seatCount, filled: occupied),
              const SizedBox(width: PsSpacing.s3),
              Text('$occupied/${table.seatCount}',
                  style: TextStyle(
                      fontSize: PsType.caption,
                      fontWeight: PsType.weightBlack,
                      color: full ? PsColors.statusFull : PsColors.text)),
              const Spacer(),
              if (waiting > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: PsColors.statusLive.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.people_alt_outlined, size: 13, color: PsColors.statusLive),
                      const SizedBox(width: 4),
                      Text('$waiting ${l10n.waitingWord}',
                          style: const TextStyle(
                              fontSize: PsType.caption,
                              fontWeight: PsType.weightBlack,
                              color: PsColors.statusLive)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NumOrb extends StatelessWidget {
  const _NumOrb({required this.number, required this.open});
  final int number;
  final bool open;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(PsRadii.md),
        gradient: open
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [PsColors.accentPrimary, PsColors.accentSecondary])
            : null,
        color: open ? null : PsColors.glassRegular,
        border: open ? null : Border.all(color: PsColors.glassBorder),
      ),
      child: Text('$number',
          style: TextStyle(
              fontSize: 22,
              fontWeight: PsType.weightBlack,
              color: open ? PsColors.onAccent : PsColors.textMuted)),
    );
  }
}

class _MiniSeats extends StatelessWidget {
  const _MiniSeats({required this.total, required this.filled});
  final int total;
  final int filled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 3),
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < filled ? PsColors.accentPrimary : Colors.transparent,
              border: Border.all(
                color: i < filled ? PsColors.accentPrimary : PsColors.glassBorder,
                width: 1.5,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

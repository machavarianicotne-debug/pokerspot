import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/features/clubs/domain/club.dart';
import 'package:pokerspot/features/clubs/presentation/providers.dart';
import 'package:pokerspot/shared/widgets/centered_pane.dart';
import 'package:pokerspot/shared/widgets/ps_card.dart';
import 'package:pokerspot/shared/widgets/ps_filter_pill.dart';
import 'package:pokerspot/shared/widgets/ps_metric.dart';
import 'package:pokerspot/shared/widgets/ps_overline.dart';
import 'package:pokerspot/shared/widgets/ps_status_badge.dart';
import 'package:pokerspot/shared/widgets/ps_toggle.dart';

/// The Player's club list (mockup `player-clubs-list`): a filter row over club
/// cards that show a live status badge and a scoreboard (open seats / stakes /
/// waitlist) for running games, or an empty/closed line otherwise. The live
/// numbers come from denormalized aggregates on the club doc (syncClubStats) —
/// players can't read other clubs' sessions/waitlist directly.
class ClubsListScreen extends ConsumerStatefulWidget {
  const ClubsListScreen({super.key});

  @override
  ConsumerState<ClubsListScreen> createState() => _ClubsListScreenState();
}

class _ClubsListScreenState extends ConsumerState<ClubsListScreen> {
  bool _openOnly = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final clubsAsync = ref.watch(clubsListProvider);
    return CenteredPane(
      child: clubsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: PsColors.accentPrimary),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(PsSpacing.s5),
            child: Text('$e',
                textAlign: TextAlign.center,
                style: const TextStyle(color: PsColors.statusLive)),
          ),
        ),
        data: (all) {
          final clubs = _openOnly ? all.where((c) => c.enabled).toList() : all;
          return ListView(
            padding: const EdgeInsets.fromLTRB(PsSpacing.s4, PsSpacing.s4, PsSpacing.s4, 96),
            children: [
              _filters(l10n),
              const SizedBox(height: PsSpacing.s5),
              if (clubs.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: PsSpacing.s8),
                  child: Center(
                    child: Text(l10n.noClubsYet,
                        style: TextStyle(color: PsColors.textMuted, fontSize: PsType.body)),
                  ),
                )
              else
                for (final c in clubs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: PsSpacing.s4),
                    child: _ClubCard(club: c),
                  ),
            ],
          );
        },
      ),
    );
  }

  Widget _filters(AppL10n l10n) => Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  PsFilterPill(label: l10n.allCitiesFilter, active: true),
                  const SizedBox(width: PsSpacing.s2),
                  const PsFilterPill(label: 'NLH · PLO'),
                ],
              ),
            ),
          ),
          const SizedBox(width: PsSpacing.s2),
          PsToggle(
            value: _openOnly,
            label: l10n.openLabel.toUpperCase(),
            onChanged: (v) => setState(() => _openOnly = v),
          ),
        ],
      );
}

class _ClubCard extends StatelessWidget {
  const _ClubCard({required this.club});
  final Club club;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final closed = !club.enabled;
    final full = club.live && club.openSeats <= 0;
    final tables = club.games.fold<int>(0, (a, g) => a + g.tables);
    final railColor = closed
        ? PsColors.statusClosed
        : full
            ? PsColors.statusFull
            : club.live
                ? PsColors.accentPrimary
                : PsColors.statusOpen;
    final status = closed
        ? PsStatus.closed
        : club.live
            ? PsStatus.live
            : PsStatus.open;
    final badgeLabel = closed
        ? l10n.closedLabel
        : club.live
            ? l10n.liveLabel
            : l10n.openLabel;

    return PsCard(
      key: Key('clubCard_${club.id}'),
      accentRail: railColor,
      padding: EdgeInsets.zero,
      onTap: closed ? null : () => context.go('/home/club/${club.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // club-head (mockup padding 14 16 10)
          Padding(
            padding: const EdgeInsets.fromLTRB(PsSpacing.s4, 14, PsSpacing.s4, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(club.name,
                          style: const TextStyle(
                              fontSize: PsType.headline,
                              fontWeight: PsType.weightBold,
                              letterSpacing: PsType.trackingSnug,
                              color: PsColors.text)),
                      const SizedBox(height: 2),
                      PsOverline(club.city),
                    ],
                  ),
                ),
                const SizedBox(width: PsSpacing.s3),
                PsStatusBadge(status: status, label: badgeLabel),
              ],
            ),
          ),
          if (club.live)
            // scoreboard (mockup padding 4 16 16)
            Padding(
              padding: const EdgeInsets.fromLTRB(PsSpacing.s4, PsSpacing.s1, PsSpacing.s4, PsSpacing.s4),
              child: Row(
                children: [
                  PsMetric(value: '$tables', label: l10n.tablesMetric, variant: PsMetricVariant.hero),
                  const SizedBox(width: PsSpacing.s3),
                  PsMetric(value: '${club.players}', label: l10n.playersLabel),
                  const SizedBox(width: PsSpacing.s3),
                  PsMetric(value: '${club.waiting}', label: l10n.waitlistTitle),
                ],
              ),
            )
          else
            // empty / closed line (mockup .empty-row, padding 14 16 16)
            Padding(
              padding: const EdgeInsets.fromLTRB(PsSpacing.s4, 14, PsSpacing.s4, PsSpacing.s4),
              child: Text(closed ? club.hoursText : l10n.floorOpenEmpty,
                  style: TextStyle(
                      fontSize: PsType.subhead,
                      fontWeight: PsType.weightMedium,
                      color: PsColors.textFaint)),
            ),
        ],
      ),
    );
  }
}

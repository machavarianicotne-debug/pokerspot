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
import 'package:pokerspot/shared/widgets/ps_settings_group.dart';
import 'package:pokerspot/shared/widgets/ps_sheet.dart';
import 'package:pokerspot/shared/widgets/ps_status_badge.dart';
import 'package:pokerspot/shared/widgets/ps_toggle.dart';

/// The Player's club list (mockup `player-clubs-list`): a filter row over club
/// cards that show a live status badge and a scoreboard (open seats / stakes /
/// waitlist) for running games, or an empty/closed line otherwise. The live
/// numbers come from denormalized aggregates on the club doc (syncClubStats) —
/// players can't read other clubs' sessions/waitlist directly.
/// "BATUMI" -> "Batumi": city names render title-cased regardless of how they
/// were stored, while the "All City" filter keeps its exact localized casing.
String _titleCase(String s) => s
    .split(' ')
    .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
    .join(' ');

class ClubsListScreen extends ConsumerStatefulWidget {
  const ClubsListScreen({super.key});

  @override
  ConsumerState<ClubsListScreen> createState() => _ClubsListScreenState();
}

class _ClubsListScreenState extends ConsumerState<ClubsListScreen> {
  bool _openOnly = false;
  String? _city; // null = All Cities

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
          final clubs = all
              .where((c) => !_openOnly || c.enabled)
              .where((c) => _city == null || c.city == _city)
              .toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(PsSpacing.s4, PsSpacing.s4, PsSpacing.s4, 96),
            children: [
              _filters(l10n, all),
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

  Widget _filters(AppL10n l10n, List<Club> all) => Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: PsFilterPill(
                label: _city == null ? l10n.allCitiesFilter : _titleCase(_city!),
                active: true,
                onTap: () => _pickCity(l10n, all),
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

  /// City filter: "All Cities" + the distinct cities of the loaded clubs.
  void _pickCity(AppL10n l10n, List<Club> all) {
    final cities = all.map((c) => c.city).where((s) => s.isNotEmpty).toSet().toList()..sort();
    PsSheet.show<void>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.allCitiesFilter,
              style: const TextStyle(
                  fontSize: PsType.headline, fontWeight: PsType.weightBold, color: PsColors.text)),
          const SizedBox(height: PsSpacing.s3),
          PsSettingsGroup(children: [
            for (final entry in <(String?, String)>[(null, l10n.allCitiesFilter), for (final c in cities) (c, c)])
              PsSettingsRow(
                label: entry.$1 == null ? entry.$2 : _titleCase(entry.$2),
                trailing: _city == entry.$1
                    ? const Icon(Icons.check, size: 18, color: PsColors.accentPrimary)
                    : null,
                onTap: () {
                  setState(() => _city = entry.$1);
                  Navigator.of(context).pop();
                },
              ),
          ]),
        ],
      ),
    );
  }
}

class _ClubCard extends StatelessWidget {
  const _ClubCard({required this.club});
  final Club club;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final closed = !club.enabled;
    // A room with open tables is LIVE — even with 0 seated players. (club.games
    // is the open-tables scoreboard; club.live only flips once someone sits.)
    final live = club.games.isNotEmpty;
    final full = live && club.openSeats <= 0;
    final tables = club.games.fold<int>(0, (a, g) => a + g.tables);
    final railColor = closed
        ? PsColors.statusClosed
        : full
            ? PsColors.statusFull
            : live
                ? PsColors.accentPrimary
                : PsColors.statusOpen;
    final status = closed
        ? PsStatus.closed
        : live
            ? PsStatus.live
            : PsStatus.open;
    final badgeLabel = closed
        ? l10n.closedLabel
        : live
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
          if (live)
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

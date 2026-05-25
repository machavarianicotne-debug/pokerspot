import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/features/admin/presentation/observe_club_screen.dart';
import 'package:pokerspot/features/floor/domain/session.dart';
import 'package:pokerspot/features/floor/presentation/providers.dart';
import 'package:pokerspot/shared/widgets/ps_button.dart';
import 'package:pokerspot/shared/widgets/ps_card.dart';
import 'package:pokerspot/shared/widgets/ps_list_tile.dart';
import 'package:pokerspot/shared/widgets/ps_metric.dart';
import 'package:pokerspot/shared/widgets/ps_overline.dart';
import 'package:pokerspot/shared/widgets/ps_scaffold.dart';

/// Basic per-club session analytics (Super Admin): totals, active count, average
/// duration and a per-stake breakdown.
class ClubAnalyticsScreen extends ConsumerWidget {
  const ClubAnalyticsScreen({super.key, required this.clubId, required this.clubName});
  final String clubId;
  final String clubName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final sessions = ref.watch(clubSessionsAllProvider(clubId)).valueOrNull ?? const <Session>[];

    final active = sessions.where((s) => s.status == SessionStatus.active).length;
    final ended = sessions.where((s) => s.status == SessionStatus.ended).toList();
    var avgMin = 0;
    if (ended.isNotEmpty) {
      final totalMin = ended.fold<int>(0, (sum, s) {
        final d = s.elapsedAt(DateTime.now());
        return sum + (d?.inMinutes ?? 0);
      });
      avgMin = (totalMin / ended.length).round();
    }
    final byStake = <String, int>{};
    for (final s in sessions) {
      byStake[s.stakes.label] = (byStake[s.stakes.label] ?? 0) + 1;
    }

    return PsScaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
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
                    child: Text('$clubName · ${l10n.analyticsTitle}',
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
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(PsSpacing.s5),
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: PsMetric(
                              value: '${sessions.length}',
                              label: l10n.sessionsLabel,
                              variant: PsMetricVariant.hero)),
                      const SizedBox(width: PsSpacing.s2),
                      Expanded(child: PsMetric(value: '$active', label: l10n.activeLabel)),
                      const SizedBox(width: PsSpacing.s2),
                      Expanded(child: PsMetric(value: '$avgMin', label: l10n.avgMinLabel)),
                    ],
                  ),
                  const SizedBox(height: PsSpacing.s4),
                  PsButton(
                    key: const Key('observeFloorBtn'),
                    label: l10n.observeFloor,
                    icon: Icons.visibility_outlined,
                    variant: PsButtonVariant.secondary,
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => ObserveClubScreen(clubId: clubId, clubName: clubName),
                    )),
                  ),
                  const SizedBox(height: PsSpacing.s5),
                  PsOverline(l10n.sessionsLabel),
                  const SizedBox(height: PsSpacing.s3),
                  for (final e in byStake.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: PsSpacing.s3),
                      child: PsCard(
                        child: PsListTile(
                          title: e.key,
                          trailing: Text('${e.value}',
                              style: const TextStyle(
                                  fontSize: PsType.body,
                                  fontWeight: PsType.weightBlack,
                                  color: PsColors.accentPrimary)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

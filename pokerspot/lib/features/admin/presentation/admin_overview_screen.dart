import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/features/admin/domain/audit_entry.dart';
import 'package:pokerspot/features/admin/presentation/club_analytics_screen.dart';
import 'package:pokerspot/features/admin/presentation/providers.dart';
import 'package:pokerspot/features/auth/domain/app_user.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';
import 'package:pokerspot/features/clubs/domain/club.dart';
import 'package:pokerspot/features/clubs/presentation/providers.dart';
import 'package:pokerspot/shared/widgets/ps_card.dart';
import 'package:pokerspot/shared/widgets/ps_list_tile.dart';
import 'package:pokerspot/shared/widgets/ps_metric.dart';
import 'package:pokerspot/shared/widgets/ps_overline.dart';

/// Super Admin "Overview" tab: network aggregates + a recent audit-log feed.
class AdminOverviewScreen extends ConsumerWidget {
  const AdminOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final clubs = ref.watch(allClubsProvider).valueOrNull ?? const <Club>[];
    final users = ref.watch(allUsersProvider).valueOrNull ?? const <AppUser>[];
    final audit = ref.watch(recentAuditProvider).valueOrNull ?? const <AuditEntry>[];
    final enabled = clubs.where((c) => c.enabled).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(PsSpacing.s4, PsSpacing.s4, PsSpacing.s4, 96),
      children: [
        Row(
          children: [
            Expanded(
                child: PsMetric(
                    value: '${clubs.length}',
                    label: l10n.tabClubs,
                    variant: PsMetricVariant.hero)),
            const SizedBox(width: PsSpacing.s2),
            Expanded(child: PsMetric(value: '${users.length}', label: l10n.tabUsers)),
            const SizedBox(width: PsSpacing.s2),
            Expanded(child: PsMetric(value: '$enabled', label: l10n.activeLabel)),
          ],
        ),
        const SizedBox(height: PsSpacing.s5),
        PsOverline(l10n.tabClubs),
        const SizedBox(height: PsSpacing.s3),
        for (final c in clubs)
          Padding(
            padding: const EdgeInsets.only(bottom: PsSpacing.s2),
            child: PsCard(
              key: Key('overviewClub_${c.id}'),
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => ClubAnalyticsScreen(clubId: c.id, clubName: c.name),
              )),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.enabled ? PsColors.accentPrimary : PsColors.statusClosed,
                    ),
                  ),
                  const SizedBox(width: PsSpacing.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name,
                            style: const TextStyle(
                                fontSize: PsType.body,
                                fontWeight: PsType.weightBold,
                                color: PsColors.text)),
                        const SizedBox(height: 2),
                        Text(c.city,
                            style: TextStyle(fontSize: PsType.caption, color: PsColors.textMuted)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 18, color: PsColors.textFaint),
                ],
              ),
            ),
          ),
        const SizedBox(height: PsSpacing.s5),
        PsOverline(l10n.analyticsTitle),
        const SizedBox(height: PsSpacing.s3),
        for (final e in audit.take(20))
          Padding(
            padding: const EdgeInsets.only(bottom: PsSpacing.s2),
            child: PsCard(
              child: PsListTile(title: e.action, subtitle: e.target),
            ),
          ),
      ],
    );
  }
}

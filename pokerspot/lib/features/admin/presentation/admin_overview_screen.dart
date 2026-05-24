import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/features/admin/domain/audit_entry.dart';
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

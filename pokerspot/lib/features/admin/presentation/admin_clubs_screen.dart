import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/features/admin/presentation/club_analytics_screen.dart';
import 'package:pokerspot/features/admin/presentation/club_editor_sheet.dart';
import 'package:pokerspot/features/admin/presentation/providers.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';
import 'package:pokerspot/features/clubs/domain/club.dart';
import 'package:pokerspot/features/clubs/presentation/providers.dart';
import 'package:pokerspot/shared/widgets/ps_button.dart';
import 'package:pokerspot/shared/widgets/ps_card.dart';
import 'package:pokerspot/shared/widgets/ps_list_tile.dart';
import 'package:pokerspot/shared/widgets/ps_toggle.dart';

/// Super Admin "Clubs" tab: all clubs (incl. disabled), create/edit, enable/
/// disable, and a tap-through to per-club analytics. Every change is audited.
class AdminClubsScreen extends ConsumerWidget {
  const AdminClubsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final clubs = ref.watch(allClubsProvider).valueOrNull ?? const <Club>[];

    return ListView(
      padding: const EdgeInsets.fromLTRB(PsSpacing.s4, PsSpacing.s4, PsSpacing.s4, 96),
      children: [
        SizedBox(
          width: double.infinity,
          child: PsButton(
            key: const Key('newClubBtn'),
            label: l10n.newClub,
            icon: Icons.add,
            onPressed: () => ClubEditorSheet.show(context),
          ),
        ),
        const SizedBox(height: PsSpacing.s4),
        if (clubs.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: PsSpacing.s8),
            child: Text(l10n.noClubsYet,
                textAlign: TextAlign.center,
                style: TextStyle(color: PsColors.textMuted, fontSize: PsType.body)),
          )
        else
          for (final c in clubs)
            Padding(
              padding: const EdgeInsets.only(bottom: PsSpacing.s3),
              child: _AdminClubCard(club: c),
            ),
      ],
    );
  }
}

class _AdminClubCard extends ConsumerWidget {
  const _AdminClubCard({required this.club});
  final Club club;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    return PsCard(
      key: Key('adminClubCard_${club.id}'),
      accentRail: club.enabled ? PsColors.accentPrimary : PsColors.statusClosed,
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => ClubAnalyticsScreen(clubId: club.id, clubName: club.name),
      )),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PsListTile(
            title: club.name,
            subtitle: club.city,
            trailing: GestureDetector(
              key: Key('editClubBtn_${club.id}'),
              onTap: () => ClubEditorSheet.show(context, existing: club),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(PsSpacing.s2),
                child: Icon(Icons.edit_outlined, size: 20, color: PsColors.textMuted),
              ),
            ),
          ),
          const SizedBox(height: PsSpacing.s2),
          PsToggle(
            value: club.enabled,
            label: l10n.enabledLabel.toUpperCase(),
            onChanged: (v) {
              final actor = ref.read(currentUserProvider).valueOrNull?.uid ?? 'admin';
              unawaited(ref.read(clubsRepositoryProvider).setClubEnabled(club.id, v));
              unawaited(ref.read(adminRepositoryProvider).log(
                  actorUid: actor,
                  action: v ? 'club.enable' : 'club.disable',
                  target: club.id));
            },
          ),
        ],
      ),
    );
  }
}

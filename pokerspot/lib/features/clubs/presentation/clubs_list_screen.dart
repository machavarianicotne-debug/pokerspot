import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/features/clubs/domain/club.dart';
import 'package:pokerspot/features/clubs/presentation/providers.dart';
import 'package:pokerspot/shared/widgets/centered_pane.dart';
import 'package:pokerspot/shared/widgets/ps_card.dart';
import 'package:pokerspot/shared/widgets/ps_overline.dart';

/// The Player's club list, embedded in PlayerHome's body.
class ClubsListScreen extends ConsumerWidget {
  const ClubsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        data: (clubs) {
          if (clubs.isEmpty) {
            return Center(
              child: Text(l10n.noClubsYet,
                  style: TextStyle(color: PsColors.textMuted, fontSize: PsType.body)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(PsSpacing.s4),
            itemCount: clubs.length,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.only(bottom: PsSpacing.s4),
              child: _ClubCard(club: clubs[i]),
            ),
          );
        },
      ),
    );
  }
}

class _ClubCard extends StatelessWidget {
  const _ClubCard({required this.club});
  final Club club;

  @override
  Widget build(BuildContext context) {
    return PsCard(
      key: Key('clubCard_${club.id}'),
      accentRail: PsColors.accentPrimary,
      onTap: () => context.go('/home/club/${club.id}'),
      padding: const EdgeInsets.fromLTRB(PsSpacing.s4, 14, PsSpacing.s4, PsSpacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            club.name,
            style: const TextStyle(
              fontSize: PsType.headline,
              fontWeight: PsType.weightBold,
              letterSpacing: PsType.trackingSnug,
              color: PsColors.text,
            ),
          ),
          const SizedBox(height: 2),
          PsOverline(club.city),
          const SizedBox(height: PsSpacing.s3),
          Text(
            club.hoursText,
            style: TextStyle(
              fontSize: PsType.subhead,
              fontWeight: PsType.weightMedium,
              color: PsColors.textFaint,
            ),
          ),
        ],
      ),
    );
  }
}

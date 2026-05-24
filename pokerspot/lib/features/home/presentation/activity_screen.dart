import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/features/floor/domain/session.dart';
import 'package:pokerspot/features/floor/presentation/my_waitlist_banner.dart';
import 'package:pokerspot/features/floor/presentation/providers.dart';
import 'package:pokerspot/shared/widgets/ps_card.dart';
import 'package:pokerspot/shared/widgets/ps_list_tile.dart';
import 'package:pokerspot/shared/widgets/ps_live_dot.dart';

/// The player's Activity tab: their active session(s) at the top and the
/// waitlist banner below; an empty state when neither exists.
class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final entries = ref.watch(myWaitlistProvider).valueOrNull ?? const [];
    final sessions = ref.watch(mySessionProvider).valueOrNull ?? const <Session>[];

    if (entries.isEmpty && sessions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(PsSpacing.s5),
          child: Text(
            l10n.noActivityYet,
            textAlign: TextAlign.center,
            style: TextStyle(color: PsColors.textMuted, fontSize: PsType.body),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, PsSpacing.s2, 0, 96),
      children: [
        for (final s in sessions)
          Padding(
            padding: const EdgeInsets.fromLTRB(PsSpacing.s4, 0, PsSpacing.s4, PsSpacing.s3),
            child: _SessionCard(session: s),
          ),
        const MyWaitlistBanner(),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session});
  final Session session;

  @override
  Widget build(BuildContext context) {
    return PsCard(
      accentRail: PsColors.accentPrimary,
      child: PsListTile(
        title: session.stakes.label,
        subtitle: '#${session.seatNumber}',
        trailing: const SizedBox(width: 16, child: Center(child: PsLiveDot())),
      ),
    );
  }
}

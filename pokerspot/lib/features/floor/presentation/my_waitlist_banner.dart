import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/features/floor/domain/waitlist_entry.dart';
import 'package:pokerspot/features/floor/presentation/providers.dart';
import 'package:pokerspot/shared/widgets/ps_card.dart';
import 'package:pokerspot/shared/widgets/ps_overline.dart';

/// The signed-in player's active waitlist entries (waiting / called) with a
/// cancel action, in a cyan-railed glass card. Renders nothing when the player
/// isn't on any waitlist.
class MyWaitlistBanner extends ConsumerWidget {
  const MyWaitlistBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final entries = ref.watch(myWaitlistProvider).valueOrNull ?? const <WaitlistEntry>[];
    if (entries.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(PsSpacing.s4, PsSpacing.s2, PsSpacing.s4, 0),
      child: PsCard(
        accentRail: PsColors.accentSecondary,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PsOverline(l10n.yourWaitlist),
            const SizedBox(height: PsSpacing.s2),
            for (final e in entries) _MyWaitlistRow(entry: e),
          ],
        ),
      ),
    );
  }
}

class _MyWaitlistRow extends ConsumerWidget {
  const _MyWaitlistRow({required this.entry});
  final WaitlistEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final called = entry.status == WaitlistStatus.called;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: PsSpacing.s1),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.stakes.label,
                  style: const TextStyle(
                    fontSize: PsType.body,
                    fontWeight: PsType.weightBold,
                    color: PsColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  called ? l10n.statusCalled : l10n.statusWaiting,
                  style: TextStyle(
                    fontSize: PsType.subhead,
                    fontWeight: called ? PsType.weightBold : PsType.weightMedium,
                    color: called ? PsColors.accentPrimary : PsColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            key: Key('cancelWaitlist_${entry.id}'),
            onTap: () => unawaited(ref.read(waitlistRepositoryProvider).cancel(entry.id)),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: PsSpacing.s2, vertical: PsSpacing.s1),
              child: Text(
                l10n.cancelWaitlist,
                style: const TextStyle(
                  fontSize: PsType.subhead,
                  fontWeight: PsType.weightBold,
                  color: PsColors.statusLive,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

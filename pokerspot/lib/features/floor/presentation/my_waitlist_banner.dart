import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/features/floor/domain/waitlist_entry.dart';
import 'package:pokerspot/features/floor/presentation/providers.dart';

/// The signed-in player's active waitlist entries (waiting / called) with a
/// cancel action. Renders nothing when the player isn't on any waitlist.
class MyWaitlistBanner extends ConsumerWidget {
  const MyWaitlistBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final entries = ref.watch(myWaitlistProvider).valueOrNull ?? const <WaitlistEntry>[];
    if (entries.isEmpty) return const SizedBox.shrink();
    return Material(
      color: PsColors.bg1,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: PsSpacing.s4, vertical: PsSpacing.s2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.yourWaitlist,
                style: TextStyle(
                    color: PsColors.textMuted, fontSize: PsType.subhead)),
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
    return ListTile(
      key: Key('myWaitlist_${entry.id}'),
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(entry.stakes.label,
          style: const TextStyle(color: PsColors.text, fontWeight: FontWeight.w700)),
      subtitle: Text(
        called ? l10n.statusCalled : l10n.statusWaiting,
        style: TextStyle(
            color: called ? PsColors.accentPrimary : PsColors.textMuted),
      ),
      trailing: TextButton(
        key: Key('cancelWaitlist_${entry.id}'),
        onPressed: () =>
            unawaited(ref.read(waitlistRepositoryProvider).cancel(entry.id)),
        child: Text(l10n.cancelWaitlist,
            style: const TextStyle(color: PsColors.statusLive)),
      ),
    );
  }
}

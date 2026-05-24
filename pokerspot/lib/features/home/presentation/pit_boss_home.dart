import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';
import 'package:pokerspot/features/floor/domain/waitlist_entry.dart';
import 'package:pokerspot/features/floor/presentation/providers.dart';

/// Pit Boss home: the live waitlist for the staff member's club
/// (`currentUser.clubId`). Call moves an entry waiting -> called.
class PitBossHome extends ConsumerWidget {
  const PitBossHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final clubId = ref.watch(currentUserProvider).valueOrNull?.clubId;
    return Scaffold(
      backgroundColor: PsColors.bg0,
      appBar: AppBar(
        backgroundColor: PsColors.bg1,
        title: Text(l10n.waitlistTitle,
            style: const TextStyle(color: PsColors.accentPrimary)),
        actions: [
          TextButton(
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
            child: Text(l10n.signOut, style: TextStyle(color: PsColors.textMuted)),
          ),
        ],
      ),
      body: clubId == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(PsSpacing.s5),
                child: Text(l10n.noClubAssigned,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: PsColors.textMuted, fontSize: PsType.body)),
              ),
            )
          : _PitBossWaitlist(clubId: clubId),
    );
  }
}

class _PitBossWaitlist extends ConsumerWidget {
  const _PitBossWaitlist({required this.clubId});
  final String clubId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final async = ref.watch(clubWaitlistProvider(clubId));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
          child: Text('$e', style: const TextStyle(color: PsColors.statusLive))),
      data: (entries) {
        if (entries.isEmpty) {
          return Center(
            child: Text(l10n.waitlistEmpty,
                style: TextStyle(color: PsColors.textMuted, fontSize: PsType.body)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(PsSpacing.s4),
          itemCount: entries.length,
          itemBuilder: (_, i) => _WaitlistRow(entry: entries[i]),
        );
      },
    );
  }
}

String _waited(WaitlistEntry e) {
  final c = e.createdAt;
  if (c == null) return '';
  return ' · ${DateTime.now().difference(c).inMinutes}m';
}

class _WaitlistRow extends ConsumerWidget {
  const _WaitlistRow({required this.entry});
  final WaitlistEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final called = entry.status == WaitlistStatus.called;
    return Card(
      color: PsColors.bg1,
      margin: const EdgeInsets.only(bottom: PsSpacing.s3),
      child: ListTile(
        key: Key('wlRow_${entry.id}'),
        title: Text(entry.playerName,
            style: const TextStyle(color: PsColors.text, fontWeight: FontWeight.w700)),
        subtitle: Text('${entry.stakes.label}${_waited(entry)}',
            style: TextStyle(color: PsColors.textMuted)),
        trailing: called
            ? Text(l10n.statusCalled,
                style: const TextStyle(color: PsColors.accentPrimary))
            : FilledButton(
                key: Key('callBtn_${entry.id}'),
                onPressed: () =>
                    unawaited(ref.read(waitlistRepositoryProvider).call(entry.id)),
                child: Text(l10n.callAction),
              ),
      ),
    );
  }
}

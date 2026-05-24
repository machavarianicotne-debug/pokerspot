import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';
import 'package:pokerspot/features/chat/domain/message.dart';
import 'package:pokerspot/features/chat/presentation/chat_thread_screen.dart';
import 'package:pokerspot/features/chat/presentation/providers.dart';
import 'package:pokerspot/shared/widgets/ps_avatar.dart';
import 'package:pokerspot/shared/widgets/ps_card.dart';
import 'package:pokerspot/shared/widgets/ps_list_tile.dart';

/// Pit Boss Inbox tab (mockup `pit-boss-inbox`): per-player chat threads for the
/// staff member's club; tap → the thread.
class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  String _initials(String s) {
    final t = s.trim();
    return t.isEmpty ? '?' : t[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final clubId = ref.watch(currentUserProvider).valueOrNull?.clubId;
    if (clubId == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(PsSpacing.s5),
          child: Text(l10n.noClubAssigned,
              textAlign: TextAlign.center,
              style: TextStyle(color: PsColors.textMuted, fontSize: PsType.body)),
        ),
      );
    }
    final threads = ref.watch(clubThreadsProvider(clubId)).valueOrNull ?? const <ChatThread>[];

    if (threads.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(PsSpacing.s5),
          child: Text(l10n.inboxEmpty,
              textAlign: TextAlign.center,
              style: TextStyle(color: PsColors.textMuted, fontSize: PsType.body)),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(PsSpacing.s4, PsSpacing.s4, PsSpacing.s4, 96),
      children: [
        for (final t in threads)
          Padding(
            padding: const EdgeInsets.only(bottom: PsSpacing.s3),
            child: PsCard(
              key: Key('thread_${t.playerUid}'),
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => ChatThreadScreen(
                  clubId: t.clubId,
                  playerUid: t.playerUid,
                  playerName: t.playerName,
                  title: t.playerName.isEmpty ? '—' : t.playerName,
                ),
              )),
              child: PsListTile(
                leading: PsAvatar(initials: _initials(t.playerName)),
                title: t.playerName.isEmpty ? '—' : t.playerName,
                subtitle: t.lastText,
              ),
            ),
          ),
      ],
    );
  }
}

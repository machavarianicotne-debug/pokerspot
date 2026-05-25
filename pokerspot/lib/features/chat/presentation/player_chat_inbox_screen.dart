import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';
import 'package:pokerspot/features/chat/domain/message.dart';
import 'package:pokerspot/features/chat/presentation/chat_thread_screen.dart';
import 'package:pokerspot/features/chat/presentation/providers.dart';
import 'package:pokerspot/features/chat/presentation/unread_badge.dart';
import 'package:pokerspot/features/clubs/domain/club.dart';
import 'package:pokerspot/features/clubs/presentation/providers.dart';
import 'package:pokerspot/shared/widgets/ps_avatar.dart';
import 'package:pokerspot/shared/widgets/ps_card.dart';
import 'package:pokerspot/shared/widgets/ps_list_tile.dart';

/// The player's Chat tab: one thread per club they've messaged with the Pit Boss.
/// No search — players start chats from a club's page; here they just read and
/// reply. Tapping a thread opens it.
class PlayerChatInboxScreen extends ConsumerWidget {
  const PlayerChatInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final threads = ref.watch(myThreadsProvider).valueOrNull ?? const <ChatThread>[];
    final clubs = ref.watch(clubsListProvider).valueOrNull ?? const <Club>[];
    final clubName = {for (final c in clubs) c.id: c.name};
    final user = ref.watch(currentUserProvider).valueOrNull;
    final myName = user == null ? '' : '${user.firstName} ${user.lastName}'.trim();

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
          () {
            final name = clubName[t.clubId] ?? l10n.chatWithPitBoss;
            return Padding(
              padding: const EdgeInsets.only(bottom: PsSpacing.s3),
              child: PsCard(
                key: Key('myThread_${t.clubId}'),
                accentRail: t.unread > 0 ? PsColors.accentPrimary : null,
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => ChatThreadScreen(
                    clubId: t.clubId,
                    playerUid: t.playerUid,
                    playerName: myName,
                    title: name,
                    subtitle: l10n.chatPeerStatus,
                  ),
                )),
                child: PsListTile(
                  leading: PsAvatar(initials: name.isEmpty ? '?' : name[0].toUpperCase()),
                  title: name,
                  subtitle: t.lastText,
                  trailing: t.unread > 0 ? UnreadBadge(count: t.unread) : null,
                ),
              ),
            );
          }(),
      ],
    );
  }
}

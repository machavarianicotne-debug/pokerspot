import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/features/auth/domain/app_user.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';
import 'package:pokerspot/features/chat/domain/message.dart';
import 'package:pokerspot/features/chat/presentation/chat_thread_screen.dart';
import 'package:pokerspot/features/chat/presentation/providers.dart';
import 'package:pokerspot/shared/widgets/ps_avatar.dart';
import 'package:pokerspot/shared/widgets/ps_card.dart';
import 'package:pokerspot/shared/widgets/ps_fab.dart';
import 'package:pokerspot/shared/widgets/ps_list_tile.dart';
import 'package:pokerspot/shared/widgets/ps_sheet.dart';
import 'package:pokerspot/shared/widgets/ps_text_field.dart';

/// Pit Boss Inbox tab (mockup `pit-boss-inbox`): per-player chat threads for the
/// staff member's club, plus a "new message" search to start a thread with any
/// registered player.
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

    return Stack(
      children: [
        if (threads.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(PsSpacing.s5),
              child: Text(l10n.inboxEmpty,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: PsColors.textMuted, fontSize: PsType.body)),
            ),
          )
        else
          ListView(
            padding: const EdgeInsets.fromLTRB(PsSpacing.s4, PsSpacing.s4, PsSpacing.s4, 96),
            children: [
              for (final t in threads)
                Padding(
                  padding: const EdgeInsets.only(bottom: PsSpacing.s3),
                  child: PsCard(
                    key: Key('thread_${t.playerUid}'),
                    onTap: () => _openThread(context, clubId, t.playerUid, t.playerName),
                    child: PsListTile(
                      leading: PsAvatar(initials: _initials(t.playerName)),
                      title: t.playerName.isEmpty ? '—' : t.playerName,
                      subtitle: t.lastText,
                    ),
                  ),
                ),
            ],
          ),
        Positioned(
          right: PsSpacing.s4,
          bottom: 88,
          child: PsFab(
            key: const Key('newChatBtn'),
            label: l10n.newChat,
            icon: Icons.edit_outlined,
            onPressed: () => unawaited(
              PsSheet.show<void>(context, child: _NewChatSheet(clubId: clubId)),
            ),
          ),
        ),
      ],
    );
  }

  static void _openThread(BuildContext context, String clubId, String playerUid, String name) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => ChatThreadScreen(
        clubId: clubId,
        playerUid: playerUid,
        playerName: name,
        title: name.isEmpty ? '—' : name,
      ),
    ));
  }
}

/// Search registered players to start a new conversation (Pit Bosses may read
/// the users collection per the rules).
class _NewChatSheet extends ConsumerStatefulWidget {
  const _NewChatSheet({required this.clubId});
  final String clubId;

  @override
  ConsumerState<_NewChatSheet> createState() => _NewChatSheetState();
}

class _NewChatSheetState extends ConsumerState<_NewChatSheet> {
  final _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  String _initials(AppUser u) {
    final a = u.firstName.trim().isNotEmpty ? u.firstName.trim()[0] : '';
    final b = u.lastName.trim().isNotEmpty ? u.lastName.trim()[0] : '';
    final s = (a + b).toUpperCase();
    return s.isEmpty ? '?' : s;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final query = _q.text.trim().toLowerCase();
    final players = (ref.watch(allUsersProvider).valueOrNull ?? const <AppUser>[])
        .where((u) => u.role == AppRole.player)
        .where((u) => query.isEmpty ||
            '${u.firstName} ${u.lastName}'.toLowerCase().contains(query) ||
            u.phone.toLowerCase().contains(query))
        .take(8)
        .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.newChat,
            style: const TextStyle(
                fontSize: PsType.headline, fontWeight: PsType.weightBold, color: PsColors.text)),
        const SizedBox(height: PsSpacing.s3),
        PsTextField(controller: _q, hintText: l10n.searchUsersHint, onChanged: (_) => setState(() {})),
        const SizedBox(height: PsSpacing.s3),
        for (final u in players)
          Padding(
            padding: const EdgeInsets.only(bottom: PsSpacing.s2),
            child: PsCard(
              key: Key('newChatUser_${u.uid}'),
              onTap: () {
                final name = '${u.firstName} ${u.lastName}'.trim();
                Navigator.of(context).pop();
                InboxScreen._openThread(context, widget.clubId, u.uid, name);
              },
              child: PsListTile(
                leading: PsAvatar(initials: _initials(u), size: 32),
                title: '${u.firstName} ${u.lastName}'.trim().isEmpty
                    ? '—'
                    : '${u.firstName} ${u.lastName}'.trim(),
                subtitle: u.phone,
              ),
            ),
          ),
      ],
    );
  }
}

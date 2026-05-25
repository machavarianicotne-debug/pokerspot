import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/features/auth/domain/app_user.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';
import 'package:pokerspot/features/chat/domain/message.dart';
import 'package:pokerspot/features/chat/presentation/providers.dart';
import 'package:pokerspot/features/home/presentation/player_profile_sheet.dart';
import 'package:pokerspot/shared/widgets/ps_avatar.dart';
import 'package:pokerspot/shared/widgets/ps_chat.dart';
import 'package:pokerspot/shared/widgets/ps_scaffold.dart';

/// A 1-on-1 chat thread (mockup `player-club-chat` / `pit-boss-chat-thread`).
/// Shared by both sides: [playerUid]/[playerName] identify the thread; the
/// caller passes the peer [title]. Sender identity comes from the current user.
class ChatThreadScreen extends ConsumerStatefulWidget {
  const ChatThreadScreen({
    super.key,
    required this.clubId,
    required this.playerUid,
    required this.playerName,
    required this.title,
  });

  final String clubId;
  final String playerUid;
  final String playerName;
  final String title;

  @override
  ConsumerState<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends ConsumerState<ChatThreadScreen> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  String _initials(String s) {
    final t = s.trim();
    return t.isEmpty ? '?' : t[0].toUpperCase();
  }

  String _time(DateTime? at) {
    if (at == null) return '';
    return '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    final user = ref.read(currentUserProvider).valueOrNull;
    final uid = ref.read(authRepositoryProvider).currentUid;
    if (user == null || uid == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppL10n.of(context);
    _input.clear();
    try {
      await ref.read(chatRepositoryProvider).send(
            clubId: widget.clubId,
            playerUid: widget.playerUid,
            playerName: widget.playerName,
            senderUid: uid,
            senderRole: user.role,
            text: text,
          );
    } catch (_) {
      // Don't lose the text on a denied/failed write — restore it and tell the user.
      _input.text = text;
      messenger.showSnackBar(SnackBar(content: Text(l10n.chatSendFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final myUid = ref.watch(authRepositoryProvider).currentUid;
    final role = ref.watch(currentUserProvider).valueOrNull?.role;
    final isStaff = role == AppRole.pitboss || role == AppRole.superadmin;
    final messages = ref
            .watch(threadProvider((clubId: widget.clubId, playerUid: widget.playerUid)))
            .valueOrNull ??
        const <Message>[];
    final reversed = messages.reversed.toList();

    return PsScaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(PsSpacing.s3, PsSpacing.s2, PsSpacing.s4, PsSpacing.s3),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.all(PsSpacing.s2),
                      child: Icon(Icons.arrow_back_ios_new, size: 18, color: PsColors.text),
                    ),
                  ),
                  const SizedBox(width: PsSpacing.s2),
                  PsAvatar(initials: _initials(widget.title)),
                  const SizedBox(width: PsSpacing.s3),
                  Expanded(
                    child: Text(widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: PsType.body,
                            fontWeight: PsType.weightBold,
                            color: PsColors.text)),
                  ),
                  // Staff can open the player's profile (name + phone).
                  if (isStaff)
                    GestureDetector(
                      key: const Key('chatPlayerProfileBtn'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => PlayerProfileSheet.show(context,
                          uid: widget.playerUid, fallbackName: widget.playerName),
                      child: Padding(
                        padding: const EdgeInsets.all(PsSpacing.s2),
                        child: Icon(Icons.info_outline, size: 20, color: PsColors.textMuted),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: messages.isEmpty
                  ? const SizedBox.expand()
                  : ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(PsSpacing.s4),
                      itemCount: reversed.length,
                      itemBuilder: (context, i) {
                        final m = reversed[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: PsSpacing.s2),
                          child: PsChatBubble(
                            text: m.text,
                            outgoing: m.senderUid == myUid,
                            time: _time(m.at),
                          ),
                        );
                      },
                    ),
            ),
            PsComposer(
              controller: _input,
              hintText: l10n.messageHint,
              onSend: () => unawaited(_send()),
            ),
          ],
        ),
      ),
    );
  }
}

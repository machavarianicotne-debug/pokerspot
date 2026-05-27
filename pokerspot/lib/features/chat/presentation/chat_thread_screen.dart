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
import 'package:pokerspot/shared/widgets/ps_sheet.dart';

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
    this.subtitle,
  });

  final String clubId;
  final String playerUid;
  final String playerName;
  final String title;

  /// Optional peer status line under the title (mockup `.chat-peer .st`).
  final String? subtitle;

  @override
  ConsumerState<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

// WhatsApp-style emoji picker (smileys + common) and quick-reaction set.
const _emojiPalette = [
  '😀', '😃', '😄', '😁', '😆', '😅', '😂', '🤣', '😊', '🙂',
  '😉', '😍', '😘', '😎', '🤔', '😐', '😴', '😢', '😭', '😡',
  '👍', '👎', '👏', '🙏', '🔥', '❤️', '🎉', '💪', '🤝', '🃏',
  '♠️', '♥️', '♦️', '♣️', '💰', '😮', '🤑', '🥳', '😬', '🤞',
];
// The 4 most-used reactions shown by default; the full palette is one tap away.
const _quickReactions = ['👍', '❤️', '😂', '🙏'];

class _ChatThreadScreenState extends ConsumerState<ChatThreadScreen> {
  final _input = TextEditingController();
  bool _showEmoji = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
  }

  /// Mark the incoming messages read for whichever side is viewing.
  void _markRead() {
    final role = ref.read(currentUserProvider).valueOrNull?.role;
    final asPit = role == AppRole.pitboss || role == AppRole.superadmin;
    unawaited(ref.read(chatRepositoryProvider).markThreadRead(
        clubId: widget.clubId, playerUid: widget.playerUid, asPit: asPit));
  }

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

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _dayLabel(DateTime at, AppL10n l10n) {
    final now = DateTime.now();
    final d = DateTime(at.year, at.month, at.day);
    final today = DateTime(now.year, now.month, now.day);
    if (d == today) return l10n.dayToday;
    if (d == today.subtract(const Duration(days: 1))) return l10n.dayYesterday;
    return '${at.day}.${at.month}';
  }

  Widget _daySep(String label) => Padding(
        padding: const EdgeInsets.symmetric(vertical: PsSpacing.s2),
        child: Text(label.toUpperCase(),
            style: TextStyle(
                fontSize: PsType.micro,
                fontWeight: PsType.weightBlack,
                letterSpacing: PsType.trackingWide,
                color: PsColors.textFaint)),
      );

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

  /// Long-press a bubble → react. The 4 most-used emojis show by default; the
  /// full palette below lets you pick any. Tapping your current reaction clears it.
  void _react(Message m, String myUid) {
    void pick(String e) {
      final nav = Navigator.of(context);
      final next = m.reactions[myUid] == e ? '' : e; // tap the same = remove
      unawaited(
          ref.read(chatRepositoryProvider).setReaction(messageId: m.id, uid: myUid, emoji: next));
      nav.pop();
    }

    PsSheet.show<void>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final e in _quickReactions)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => pick(e),
                  child: Text(e, style: const TextStyle(fontSize: 38)),
                ),
            ],
          ),
          const SizedBox(height: PsSpacing.s3),
          Divider(height: 1, color: PsColors.glassBorder),
          const SizedBox(height: PsSpacing.s2),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              children: [
                for (final e in _emojiPalette)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => pick(e),
                    child: Center(child: Text(e, style: const TextStyle(fontSize: 30))),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Emoji picker shown above the composer; tapping inserts into the input.
  Widget _emojiPanel() => Container(
        height: 220,
        color: PsColors.glassThick,
        padding: const EdgeInsets.symmetric(horizontal: PsSpacing.s3, vertical: PsSpacing.s2),
        child: GridView.count(
          crossAxisCount: 7,
          children: [
            for (final e in _emojiPalette)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  _input.text += e;
                  _input.selection = TextSelection.collapsed(offset: _input.text.length);
                },
                child: Center(child: Text(e, style: const TextStyle(fontSize: 30))),
              ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final myUid = ref.watch(authRepositoryProvider).currentUid;
    final role = ref.watch(currentUserProvider).valueOrNull?.role;
    final isStaff = role == AppRole.pitboss || role == AppRole.superadmin;
    // New messages arriving while the thread is open get marked read too.
    ref.listen(threadProvider((clubId: widget.clubId, playerUid: widget.playerUid)),
        (_, __) => _markRead());
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: PsType.body,
                                fontWeight: PsType.weightBold,
                                color: PsColors.text)),
                        if (widget.subtitle != null)
                          Text('● ${widget.subtitle}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: PsType.micro,
                                  fontWeight: PsType.weightBold,
                                  color: PsColors.accentPrimary)),
                      ],
                    ),
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
              // Tapping the message area closes the emoji panel (and the keyboard).
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  FocusScope.of(context).unfocus();
                  if (_showEmoji) setState(() => _showEmoji = false);
                },
                child: messages.isEmpty
                  ? const SizedBox.expand()
                  : ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(PsSpacing.s4),
                      itemCount: reversed.length,
                      itemBuilder: (context, i) {
                        final m = reversed[i];
                        // reversed[i+1] is the next-older message; if it's on a
                        // different day (or absent), m starts a new day → label it.
                        final older = i + 1 < reversed.length ? reversed[i + 1] : null;
                        final showDay = m.at != null && (older?.at == null || !_sameDay(m.at!, older!.at!));
                        final bubble = Padding(
                          padding: const EdgeInsets.only(bottom: PsSpacing.s2),
                          child: PsChatBubble(
                            text: m.text,
                            outgoing: m.senderUid == myUid,
                            time: _time(m.at),
                            reactions: m.reactions.values.toSet().toList(),
                            onLongPress: myUid == null ? null : () => _react(m, myUid),
                          ),
                        );
                        if (!showDay) return bubble;
                        return Column(
                          children: [_daySep(_dayLabel(m.at!, l10n)), bubble],
                        );
                      },
                    ),
              ),
            ),
            if (_showEmoji) _emojiPanel(),
            PsComposer(
              controller: _input,
              hintText: l10n.messageHint,
              onSend: () => unawaited(_send()),
              onEmoji: () => setState(() => _showEmoji = !_showEmoji),
            ),
          ],
        ),
      ),
    );
  }
}

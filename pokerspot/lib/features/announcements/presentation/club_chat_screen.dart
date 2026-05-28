import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/features/announcements/domain/announcement.dart';
import 'package:pokerspot/features/announcements/presentation/providers.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';
import 'package:pokerspot/shared/widgets/ps_chat.dart';
import 'package:pokerspot/shared/widgets/ps_sheet.dart';

// Same 40-emoji palette + 4 quick-reactions as the 1-on-1 chat, kept in sync
// by hand (each is a one-line const list; not worth a shared dependency yet).
const _emojiPalette = [
  '😀', '😃', '😄', '😁', '😆', '😅', '😂', '🤣', '😊', '🙂',
  '😉', '😍', '😘', '😎', '🤔', '😐', '😴', '😢', '😭', '😡',
  '👍', '👎', '👏', '🙏', '🔥', '❤️', '🎉', '💪', '🤝', '🃏',
  '♠️', '♥️', '♦️', '♣️', '💰', '😮', '🤑', '🥳', '😬', '🤞',
];
const _quickReactions = ['👍', '❤️', '😂', '🙏'];

/// Club Chat broadcast feed (one Pit-Boss bubble per post). Returns a column
/// body without its own Scaffold/navbar — meant to live inside a parent screen
/// (the chat hub) that owns the chrome.
class ClubChatScreen extends ConsumerStatefulWidget {
  const ClubChatScreen({super.key, required this.clubId, required this.isStaff});
  final String clubId;
  final bool isStaff;

  @override
  ConsumerState<ClubChatScreen> createState() => _ClubChatScreenState();
}

class _ClubChatScreenState extends ConsumerState<ClubChatScreen> {
  final _input = TextEditingController();
  bool _showEmoji = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
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
    _input.clear();
    await ref.read(announcementsRepositoryProvider).post(
          clubId: widget.clubId,
          senderUid: uid,
          senderName: '${user.firstName} ${user.lastName}'.trim(),
          text: text,
        );
  }

  /// Long-press a bubble — staff get Edit/Delete on their own posts; everyone
  /// else gets the reaction picker.
  void _bubbleActions(Announcement a, String myUid) {
    if (widget.isStaff && a.senderUid == myUid) {
      _staffActions(a);
    } else {
      _react(a, myUid);
    }
  }

  void _staffActions(Announcement a) {
    final l10n = AppL10n.of(context);
    PsSheet.show<void>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            key: Key('editAnn_${a.id}'),
            leading: const Icon(Icons.edit_outlined, color: PsColors.text),
            title: Text(l10n.editLabel,
                style: const TextStyle(color: PsColors.text)),
            onTap: () {
              Navigator.of(context).pop();
              _openEditor(a);
            },
          ),
          ListTile(
            key: Key('deleteAnn_${a.id}'),
            leading: const Icon(Icons.delete_outline, color: PsColors.statusLive),
            title: Text(l10n.deleteLabel,
                style: const TextStyle(color: PsColors.statusLive)),
            onTap: () {
              Navigator.of(context).pop();
              unawaited(
                  ref.read(announcementsRepositoryProvider).delete(a.id));
            },
          ),
        ],
      ),
    );
  }

  void _openEditor(Announcement a) {
    final ctl = TextEditingController(text: a.text);
    PsSheet.show<void>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('editAnnField'),
            controller: ctl,
            autofocus: true,
            maxLines: null,
            style: const TextStyle(color: PsColors.text, fontSize: PsType.body),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: PsSpacing.s3),
          ElevatedButton(
            key: const Key('saveEditAnnBtn'),
            onPressed: () {
              final next = ctl.text.trim();
              Navigator.of(context).pop();
              if (next.isEmpty || next == a.text) return;
              unawaited(ref.read(announcementsRepositoryProvider)
                  .edit(announcementId: a.id, newText: next));
            },
            child: Text(AppL10n.of(context).saveLabel),
          ),
        ],
      ),
    );
  }

  void _react(Announcement a, String myUid) {
    void pick(String e) {
      final nav = Navigator.of(context);
      final next = a.reactions[myUid] == e ? '' : e;
      unawaited(ref.read(announcementsRepositoryProvider)
          .setReaction(announcementId: a.id, uid: myUid, emoji: next));
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

  Widget _emojiPanel() => Container(
        height: 220,
        color: PsColors.glassThick,
        padding: const EdgeInsets.symmetric(
            horizontal: PsSpacing.s3, vertical: PsSpacing.s2),
        child: GridView.count(
          crossAxisCount: 7,
          children: [
            for (final e in _emojiPalette)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  _input.text += e;
                  _input.selection =
                      TextSelection.collapsed(offset: _input.text.length);
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
    final list = ref.watch(clubAnnouncementsProvider(widget.clubId)).valueOrNull ??
        const <Announcement>[];
    final reversed = list.reversed.toList();

    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              FocusScope.of(context).unfocus();
              if (_showEmoji) setState(() => _showEmoji = false);
            },
            child: list.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(PsSpacing.s5),
                      child: Text(l10n.clubChatEmpty,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: PsColors.textMuted, fontSize: PsType.body)),
                    ),
                  )
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(PsSpacing.s4),
                    itemCount: reversed.length,
                    itemBuilder: (context, i) {
                      final a = reversed[i];
                      return Padding(
                        key: Key('annBubble_${a.id}'),
                        padding: const EdgeInsets.only(bottom: PsSpacing.s2),
                        child: PsChatBubble(
                          text: a.text,
                          // Staff see their own posts on the right; players see
                          // everything on the left (incoming).
                          outgoing: widget.isStaff && a.senderUid == myUid,
                          time: _time(a.createdAt),
                          reactions: a.reactions.values.toSet().toList(),
                          onLongPress: myUid == null ? null : () => _bubbleActions(a, myUid),
                        ),
                      );
                    },
                  ),
          ),
        ),
        if (widget.isStaff && _showEmoji) _emojiPanel(),
        if (widget.isStaff)
          PsComposer(
            controller: _input,
            hintText: l10n.clubChatPostHint,
            onSend: () => unawaited(_send()),
            onEmoji: () => setState(() => _showEmoji = !_showEmoji),
          ),
      ],
    );
  }
}

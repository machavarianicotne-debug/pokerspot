import 'package:flutter/material.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/features/announcements/presentation/club_chat_screen.dart';
import 'package:pokerspot/features/chat/presentation/chat_thread_screen.dart';
import 'package:pokerspot/features/chat/presentation/inbox_screen.dart';
import 'package:pokerspot/shared/widgets/ps_scaffold.dart';

/// Player chat hub: a 2-tab wrapper opened from a club details `_ChatEntry`.
/// Tab 0 = the existing 1-on-1 thread with the Pit Boss; tab 1 = the new
/// one-way Club Chat broadcast feed.
class PlayerChatHubScreen extends StatefulWidget {
  const PlayerChatHubScreen({
    super.key,
    required this.clubId,
    required this.playerUid,
    required this.playerName,
    required this.clubName,
  });

  final String clubId;
  final String playerUid;
  final String playerName;
  final String clubName;

  @override
  State<PlayerChatHubScreen> createState() => _PlayerChatHubScreenState();
}

class _PlayerChatHubScreenState extends State<PlayerChatHubScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return PsScaffold(
      body: SafeArea(
        child: Column(
          children: [
            _ChatHubTabs(
              labels: [l10n.chatWithPitBoss, '${widget.clubName} ${l10n.clubChatTitle}'],
              index: _tab,
              onTap: (i) => setState(() => _tab = i),
            ),
            Expanded(
              child: IndexedStack(
                index: _tab,
                children: [
                  // Tab 0: the existing thread, embedded as-is.
                  ChatThreadScreen(
                    clubId: widget.clubId,
                    playerUid: widget.playerUid,
                    playerName: widget.playerName,
                    title: widget.clubName,
                    subtitle: l10n.chatPeerStatus,
                  ),
                  // Tab 1: the one-way Club Chat (player view = read-only + reactions).
                  ClubChatScreen(clubId: widget.clubId, isStaff: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pit Boss chat hub: tab 0 = the existing player inbox; tab 1 = the same
/// Club Chat broadcast feed but with composer + edit/delete (isStaff: true).
class PitChatHubScreen extends StatefulWidget {
  const PitChatHubScreen({super.key, required this.clubId, required this.clubName});
  final String clubId;
  final String clubName;

  @override
  State<PitChatHubScreen> createState() => _PitChatHubScreenState();
}

class _PitChatHubScreenState extends State<PitChatHubScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Column(
      children: [
        _ChatHubTabs(
          labels: [l10n.inboxTab, '${widget.clubName} ${l10n.clubChatTitle}'],
          index: _tab,
          onTap: (i) => setState(() => _tab = i),
        ),
        Expanded(
          child: IndexedStack(
            index: _tab,
            children: [
              const InboxScreen(),
              ClubChatScreen(clubId: widget.clubId, isStaff: true),
            ],
          ),
        ),
      ],
    );
  }
}

/// Shared 2-segment tab switcher used by both hubs.
class _ChatHubTabs extends StatelessWidget {
  const _ChatHubTabs({required this.labels, required this.index, required this.onTap});
  final List<String> labels;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(PsSpacing.s4, PsSpacing.s3, PsSpacing.s4, PsSpacing.s2),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i == labels.length - 1 ? 0 : PsSpacing.s2),
                child: GestureDetector(
                  key: Key('chatHubTab_$i'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: PsSpacing.s2),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == index ? PsColors.accentPrimary : PsColors.glassRegular,
                      borderRadius: BorderRadius.circular(PsRadii.full),
                      border: Border.all(color: PsColors.glassBorder),
                    ),
                    child: Text(
                      labels[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: PsType.body,
                          fontWeight: PsType.weightBlack,
                          color: i == index ? PsColors.onAccent : PsColors.text),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

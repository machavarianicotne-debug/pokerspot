import 'package:flutter/material.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/features/announcements/presentation/club_chat_screen.dart';
import 'package:pokerspot/features/chat/presentation/inbox_screen.dart';
import 'package:pokerspot/shared/widgets/ps_chat.dart';

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
        PsChatHubTabs(
          labels: [l10n.inboxTab, '${widget.clubName} ${l10n.clubChatTitle}'],
          index: _tab,
          onTap: (i) => setState(() => _tab = i),
        ),
        Expanded(
          child: IndexedStack(
            index: _tab,
            children: [
              const InboxScreen(),
              // The 96 padding matches InboxScreen's bottom list pad — clears
              // the TabShell's floating PsTabBar so the composer stays visible.
              ClubChatScreen(clubId: widget.clubId, isStaff: true, bottomPadding: 96),
            ],
          ),
        ),
      ],
    );
  }
}

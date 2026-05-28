import 'package:flutter/material.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/features/announcements/presentation/club_chat_screen.dart';
import 'package:pokerspot/features/chat/presentation/inbox_screen.dart';

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

/// Shared 2-segment tab switcher used by the Pit hub.
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

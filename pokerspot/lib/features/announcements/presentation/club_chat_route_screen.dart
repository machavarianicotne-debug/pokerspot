import 'package:flutter/material.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/features/announcements/presentation/club_chat_screen.dart';
import 'package:pokerspot/shared/widgets/ps_avatar.dart';
import 'package:pokerspot/shared/widgets/ps_scaffold.dart';

/// Full-screen pushed wrapper that hosts the read-only [ClubChatScreen] for a
/// player — a header (back button + club avatar + name) over the broadcast
/// feed. The list itself is owned by [ClubChatScreen]; this widget only
/// supplies chrome (it does NOT mount a composer; players don't post).
class ClubChatRouteScreen extends StatelessWidget {
  const ClubChatRouteScreen({
    super.key,
    required this.clubId,
    required this.clubName,
  });

  final String clubId;
  final String clubName;

  @override
  Widget build(BuildContext context) {
    return PsScaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  PsSpacing.s3, PsSpacing.s2, PsSpacing.s4, PsSpacing.s3),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.all(PsSpacing.s2),
                      child: Icon(Icons.arrow_back_ios_new,
                          size: 18, color: PsColors.text),
                    ),
                  ),
                  const SizedBox(width: PsSpacing.s2),
                  PsAvatar(
                      initials: clubName.isEmpty ? '?' : clubName[0].toUpperCase()),
                  const SizedBox(width: PsSpacing.s3),
                  Expanded(
                    child: Text(clubName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: PsType.body,
                            fontWeight: PsType.weightBold,
                            color: PsColors.text)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ClubChatScreen(clubId: clubId, isStaff: false),
            ),
          ],
        ),
      ),
    );
  }
}

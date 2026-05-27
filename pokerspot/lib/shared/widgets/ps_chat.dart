import 'package:flutter/material.dart';
import 'package:pokerspot/core/theme/tokens.dart';

/// Liquid Sport chat bubble (mockup `.msg`/`.bubble`). Outgoing bubbles fill
/// accent-primary (on-accent text), incoming are glass; the tail corner is
/// squared. [time] shows below.
class PsChatBubble extends StatelessWidget {
  const PsChatBubble({
    super.key,
    required this.text,
    required this.outgoing,
    this.time,
    this.reactions = const [],
    this.onLongPress,
  });

  final String text;
  final bool outgoing;
  final String? time;

  /// Distinct emoji reactions to show under the bubble (e.g. ['👍','❤️']).
  final List<String> reactions;

  /// Long-press the bubble (used to open the reaction picker).
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: outgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: outgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPress: onLongPress,
            behavior: HitTestBehavior.opaque,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                decoration: BoxDecoration(
                  color: outgoing ? PsColors.accentPrimary : PsColors.glassRegular,
                  border: outgoing ? null : Border.all(color: PsColors.glassBorder),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(outgoing ? 18 : 5),
                    bottomRight: Radius.circular(outgoing ? 5 : 18),
                  ),
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: PsType.body,
                    height: 1.35,
                    fontWeight: outgoing ? PsType.weightMedium : PsType.weightRegular,
                    color: outgoing ? PsColors.onAccent : PsColors.text,
                  ),
                ),
              ),
            ),
          ),
          if (reactions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: PsColors.glassRegular,
                  borderRadius: BorderRadius.circular(PsRadii.full),
                  border: Border.all(color: PsColors.glassBorder),
                ),
                child: Text(reactions.join(' '), style: const TextStyle(fontSize: 16)),
              ),
            ),
          if (time != null)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(time!, style: TextStyle(fontSize: 10, color: PsColors.textFaint)),
            ),
        ],
      ),
    );
  }
}

/// Liquid Sport chat composer (mockup `.composer`): a glass-thick bar with a
/// rounded text field + circular accent send button.
class PsComposer extends StatelessWidget {
  const PsComposer({
    super.key,
    required this.controller,
    required this.onSend,
    this.hintText = 'Message…',
    this.onEmoji,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final String hintText;

  /// Tapped to open the emoji picker (no button shown when null).
  final VoidCallback? onEmoji;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: PsGlass.backdrop(PsGlass.blurThick),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: PsColors.glassThick,
            border: Border(top: BorderSide(color: PsColors.glassBorder)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                if (onEmoji != null) ...[
                  GestureDetector(
                    onTap: onEmoji,
                    behavior: HitTestBehavior.opaque,
                    child: Icon(Icons.emoji_emotions_outlined,
                        size: 26, color: PsColors.textMuted),
                  ),
                  const SizedBox(width: PsSpacing.s2),
                ],
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 42),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: PsColors.glassThin,
                      borderRadius: BorderRadius.circular(PsRadii.full),
                      border: Border.all(color: PsColors.glassBorder),
                    ),
                    child: TextField(
                      controller: controller,
                      cursorColor: PsColors.accentSecondary,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => onSend(),
                      style: const TextStyle(fontSize: PsType.body, color: PsColors.text),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 11),
                        hintText: hintText,
                        hintStyle: TextStyle(fontSize: PsType.body, color: PsColors.textFaint),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: PsSpacing.s2),
                GestureDetector(
                  onTap: onSend,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: PsColors.accentPrimary,
                    ),
                    child: const Icon(Icons.send, size: 20, color: PsColors.onAccent),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

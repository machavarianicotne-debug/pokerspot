import 'package:flutter/material.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
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

/// Two-segment chat tab switcher used by both chat hubs (Pit Boss's
/// Inbox/Club Chat and Player's Direct Messages/Club Chats).
class PsChatHubTabs extends StatelessWidget {
  const PsChatHubTabs({
    super.key,
    required this.labels,
    required this.index,
    required this.onTap,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          PsSpacing.s4, PsSpacing.s3, PsSpacing.s4, PsSpacing.s2),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                    right: i == labels.length - 1 ? 0 : PsSpacing.s2),
                child: GestureDetector(
                  key: Key('chatHubTab_$i'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: PsSpacing.s2),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == index
                          ? PsColors.accentPrimary
                          : PsColors.glassRegular,
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
                          color: i == index
                              ? PsColors.onAccent
                              : PsColors.text),
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

/// WhatsApp-style day separator shown above the first bubble of each day in a
/// chat feed. Renders the day as "Today" / "Yesterday" / "April 1" (current
/// year) / "April 1, 2024" (older), localized via the current locale's month
/// names.
class PsChatDaySeparator extends StatelessWidget {
  const PsChatDaySeparator({super.key, required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: PsSpacing.s2),
      child: Center(
        child: Text(psChatDayLabel(context, date).toUpperCase(),
            style: TextStyle(
                fontSize: PsType.micro,
                fontWeight: PsType.weightBlack,
                letterSpacing: PsType.trackingWide,
                color: PsColors.textFaint)),
      ),
    );
  }
}

/// Build the localized day label used by [PsChatDaySeparator]. Exposed so day
/// boundary detection in feeds can reuse the exact same formatting.
String psChatDayLabel(BuildContext context, DateTime at) {
  final l10n = AppL10n.of(context);
  final now = DateTime.now();
  final d = DateTime(at.year, at.month, at.day);
  final today = DateTime(now.year, now.month, now.day);
  if (d == today) return l10n.dayToday;
  if (d == today.subtract(const Duration(days: 1))) return l10n.dayYesterday;
  final code = Localizations.localeOf(context).languageCode;
  final month = _monthName(code, at.month);
  if (at.year == now.year) return '$month ${at.day}';
  return '$month ${at.day}, ${at.year}';
}

const _monthsEn = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];
const _monthsKa = [
  'იანვარი', 'თებერვალი', 'მარტი', 'აპრილი', 'მაისი', 'ივნისი',
  'ივლისი', 'აგვისტო', 'სექტემბერი', 'ოქტომბერი', 'ნოემბერი', 'დეკემბერი',
];
const _monthsRu = [
  'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
  'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
];

String _monthName(String langCode, int month) {
  final names = switch (langCode) {
    'ka' => _monthsKa,
    'ru' => _monthsRu,
    _ => _monthsEn,
  };
  return names[month - 1];
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

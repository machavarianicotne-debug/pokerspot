import 'package:flutter/material.dart';
import 'package:pokerspot/core/theme/tokens.dart';

/// A small red count pill for unread messages (mockup `.tab-badge`).
class UnreadBadge extends StatelessWidget {
  const UnreadBadge({super.key, required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 20),
      height: 20,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: PsColors.statusLive,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(count > 99 ? '99+' : '$count',
          style: const TextStyle(
              fontSize: PsType.caption, fontWeight: PsType.weightBlack, color: Colors.white)),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:pokerspot/core/theme/tokens.dart';

/// Liquid Sport bottom sheet: a glass-thick, top-rounded surface with a grabber,
/// hosting the join-waitlist / seat pickers. Use [PsSheet.show] to present it
/// over a dimmed barrier. vs showModalBottomSheet's default: glass background +
/// grabber instead of an opaque Material card.
class PsSheet extends StatelessWidget {
  const PsSheet({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(PsSpacing.s5, PsSpacing.s3, PsSpacing.s5, PsSpacing.s5),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Presents [child] inside a [PsSheet] over a dimmed, scroll-controlled modal.
  static Future<T?> show<T>(BuildContext context, {required Widget child}) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => PsSheet(child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.vertical(top: Radius.circular(PsRadii.xl));
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: PsGlass.backdrop(PsGlass.blurThick),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: PsColors.glassThick,
            borderRadius: radius,
            border: Border(top: BorderSide(color: PsColors.glassBorder)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: PsSpacing.s2, bottom: PsSpacing.s3),
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(PsRadii.full),
                  ),
                ),
                Padding(padding: padding, child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

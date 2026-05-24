import 'package:flutter/material.dart';
import 'package:pokerspot/core/theme/tokens.dart';

/// Liquid Sport text field (`.ps-input`): 50px min-height, glass-thin fill,
/// radius-md, body text. On focus the border turns accent-secondary with a
/// `0 0 0 4px` cyan glow; an [errorText] turns the border status-full and
/// shows a caption below. vs Material TextField: no underline/label float,
/// glass surface, custom focus ring.
class PsTextField extends StatefulWidget {
  const PsTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.onChanged,
    this.onSubmitted,
    this.errorText,
    this.autofocus = false,
    this.enabled = true,
    this.textInputAction,
    this.maxLength,
    this.prefixText,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? errorText;
  final bool autofocus;
  final bool enabled;
  final TextInputAction? textInputAction;
  final int? maxLength;
  final String? prefixText;

  @override
  State<PsTextField> createState() => _PsTextFieldState();
}

class _PsTextFieldState extends State<PsTextField> {
  FocusNode? _internalNode;
  FocusNode get _node => widget.focusNode ?? (_internalNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _node.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _node.removeListener(_onFocusChange);
    _internalNode?.dispose();
    super.dispose();
  }

  void _onFocusChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;
    final focused = _node.hasFocus;
    final borderColor = hasError
        ? PsColors.statusFull
        : focused
            ? PsColors.accentSecondary
            : PsColors.glassBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: PsMotion.fast,
          curve: PsMotion.ease,
          constraints: const BoxConstraints(minHeight: 50),
          decoration: BoxDecoration(
            color: PsColors.glassThin,
            borderRadius: BorderRadius.circular(PsRadii.md),
            border: Border.all(color: borderColor),
            boxShadow: focused && !hasError
                ? [
                    BoxShadow(
                      color: PsColors.accentSecondary.withValues(alpha: 0.18),
                      spreadRadius: 4,
                    ),
                  ]
                : null,
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _node,
            keyboardType: widget.keyboardType,
            obscureText: widget.obscureText,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            autofocus: widget.autofocus,
            enabled: widget.enabled,
            textInputAction: widget.textInputAction,
            maxLength: widget.maxLength,
            cursorColor: PsColors.accentSecondary,
            style: const TextStyle(
              fontSize: PsType.body,
              fontWeight: PsType.weightMedium,
              color: PsColors.text,
            ),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: PsSpacing.s4,
                vertical: 15,
              ),
              hintText: widget.hintText,
              hintStyle: TextStyle(
                fontSize: PsType.body,
                fontWeight: PsType.weightRegular,
                color: PsColors.textFaint,
              ),
              prefixText: widget.prefixText,
              prefixStyle: TextStyle(
                fontSize: PsType.body,
                fontWeight: PsType.weightMedium,
                color: PsColors.textMuted,
              ),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: PsSpacing.s1, left: PsSpacing.s2),
            child: Text(
              widget.errorText!,
              style: const TextStyle(
                fontSize: PsType.caption,
                fontWeight: PsType.weightMedium,
                color: PsColors.statusFull,
              ),
            ),
          ),
      ],
    );
  }
}

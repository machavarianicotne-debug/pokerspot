import 'package:flutter/material.dart';
import 'package:pokerspot/core/theme/tokens.dart';

/// App background scaffold — the Liquid Sport gradient: a vertical base
/// (bg-1 -> bg-0) with two radial "blooms" (cyan top-left, lime top-right),
/// matching `body`/`.ps-phone` in the mockups. Replaces a flat Scaffold color.
class PsScaffold extends StatelessWidget {
  const PsScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.extendBodyBehindAppBar = true,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final bool extendBodyBehindAppBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PsColors.bg0,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      body: RepaintBoundary(
        child: DecoratedBox(
          decoration: const BoxDecoration(gradient: PsGradients.backgroundBase),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // cyan bloom — radial at ~20% x, 0% y
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.6, -1.0),
                    radius: 1.1,
                    colors: [PsColors.bgBloomA, Colors.transparent],
                    stops: const [0.0, 0.55],
                  ),
                ),
              ),
              // lime bloom — radial at ~95% x, 12% y
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.9, -0.76),
                    radius: 1.0,
                    colors: [PsColors.bgBloomB, Colors.transparent],
                    stops: const [0.0, 0.5],
                  ),
                ),
              ),
              // Every grouped glass surface in the body (PsCard, PsSettingsGroup)
              // shares ONE backdrop blur of this static background instead of each
              // doing its own expensive backdrop readback per frame — smooth
              // scrolling, visually identical to per-card blur.
              BackdropGroup(child: body),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../core/design.dart';
import '../threed/scenes/emblem_scene.dart';
import '../threed/scene_view.dart';
import '../threed/renderer.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..forward();

  late final Animation<double> _brandOpacity = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.05, 0.5, curve: Curves.easeOut),
  );
  late final Animation<double> _brandSlide =
      Tween<double>(begin: 22, end: 0).animate(
    CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.05, 0.6, curve: Curves.easeOutCubic)),
  );
  late final Animation<double> _tagOpacity = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.35, 0.8, curve: Curves.easeOut),
  );
  late final Animation<double> _loader = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.2, 0.95, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Scaffold(
      backgroundColor: TfColors.ink,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CinematicScene(
            builder: buildEmblemScene,
            telemetry: const SceneTelemetry(),
            interactive: false,
            autoRotate: true,
            reducedMotion: reduced,
            highQuality: true,
            showLabels: false,
            initialYaw: 0.1,
            initialPitch: 0.24,
            initialDistance: 10.5,
            semanticLabel: 'TrustFarm animated emblem',
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  TfColors.ink.withValues(alpha: 0.1),
                  TfColors.ink.withValues(alpha: 0.85),
                ],
                stops: const [0.35, 0.62, 1],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
              child: Column(
                children: [
                  const Spacer(),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      return Transform.translate(
                        offset: Offset(0, _brandSlide.value),
                        child: Opacity(
                          opacity: _brandOpacity.value,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: TfColors.mint.withValues(alpha: 0.08),
                                  borderRadius:
                                      BorderRadius.circular(TfRadius.pill),
                                  border: Border.all(
                                      color: TfColors.mint
                                          .withValues(alpha: 0.22)),
                                ),
                                child: Text(
                                  'TRUSTED AI IRRIGATION · FARM ENERGY',
                                  style: TfType.label(
                                      color: TfColors.mint, size: 8.5),
                                ),
                              ),
                              const SizedBox(height: 20),
                              ShaderMask(
                                blendMode: BlendMode.srcIn,
                                shaderCallback: (bounds) =>
                                    const LinearGradient(
                                  colors: [
                                    Color(0xFFFFFFFF),
                                    Color(0xFFB8FFE2),
                                    Color(0xFF62E4AC)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ).createShader(bounds),
                                child: Text(
                                  'TrustFarm',
                                  style: TfType.display(58)
                                      .copyWith(letterSpacing: -2.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  AnimatedBuilder(
                    animation: _tagOpacity,
                    builder: (context, _) => Opacity(
                      opacity: _tagOpacity.value,
                      child: Text(
                        'Trust before advice.',
                        style: TfType.body(14, color: TfColors.textDim),
                      ),
                    ),
                  ),
                  const SizedBox(height: 46),
                  SizedBox(
                    width: 132,
                    height: 2,
                    child: AnimatedBuilder(
                      animation: _loader,
                      builder: (context, _) => Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: _loader.value,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [
                                Colors.transparent,
                                TfColors.mint,
                                TfColors.cyan
                              ]),
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                BoxShadow(
                                    color: TfColors.mint.withValues(alpha: 0.6),
                                    blurRadius: 10)
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'SENSE · VERIFY · PREDICT · ADVISE',
                    style: TfType.label(size: 8, color: TfColors.textMuted),
                  ),
                  const Spacer(),
                  Text(
                    'ICBT INNOVA 2026',
                    style: TfType.label(
                        size: 8,
                        color: TfColors.textMuted.withValues(alpha: 0.8)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'renderer.dart';
import 'vector.dart';

class CinematicScene extends StatefulWidget {
  const CinematicScene({
    super.key,
    required this.builder,
    required this.telemetry,
    this.interactive = true,
    this.autoRotate = true,
    this.reducedMotion = false,
    this.highQuality = true,
    this.showLabels = true,
    this.compactLabels = false,
    this.onHotspotTap,
    this.initialYaw = 0.58,
    this.initialPitch = 0.34,
    this.initialDistance = 16,
    this.semanticLabel = 'Interactive 3D farm digital twin',
    this.allowZoom = true,
  });

  final SceneWorldBuilder builder;
  final SceneTelemetry telemetry;
  final bool interactive;
  final bool autoRotate;
  final bool reducedMotion;
  final bool highQuality;
  final bool showLabels;
  final bool compactLabels;
  final void Function(Hotspot3D hotspot)? onHotspotTap;
  final double initialYaw;
  final double initialPitch;
  final double initialDistance;
  final String semanticLabel;
  final bool allowZoom;

  @override
  State<CinematicScene> createState() => _CinematicSceneState();
}

class _CinematicSceneState extends State<CinematicScene>
    with SingleTickerProviderStateMixin {
  late final OrbitCamera _camera = OrbitCamera(
    yaw: widget.initialYaw - 0.42,
    pitch: math.max(0.05, widget.initialPitch - 0.16),
    distance: widget.initialDistance + 9,
    target: const Vec3(0, 1.6, 0),
  );
  final SceneRuntime _runtime = SceneRuntime();
  final SceneInteraction _interaction = SceneInteraction();
  final ValueNotifier<int> _repaint = ValueNotifier(0);

  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  double _intro = 0;
  double _startDistance = 16;
  double _averageFrame = 1 / 60;
  int _sampleCount = 0;

  @override
  void initState() {
    super.initState();
    _runtime.showLabels = widget.showLabels;
    _runtime.compactLabels = widget.compactLabels;
    _runtime.quality = widget.highQuality ? 1 : 0.6;
    _ticker = createTicker(_onTick)..start();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _setFinalCamera();
      _repaint.value++;
    });
  }

  @override
  void didUpdateWidget(covariant CinematicScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    _runtime.showLabels = widget.showLabels;
    _runtime.compactLabels = widget.compactLabels;
    if (!widget.highQuality) {
      _runtime.quality = 0.6;
    }
    if (oldWidget.reducedMotion != widget.reducedMotion ||
        oldWidget.autoRotate != widget.autoRotate) {
      _camera.yaw = widget.initialYaw;
      _repaint.value++;
    }
    _repaint.value++;
  }

  bool get _motionOff =>
      widget.reducedMotion ||
      (MediaQuery.maybeOf(context)?.disableAnimations ?? false);

  void _setFinalCamera() {
    _camera
      ..yaw = widget.initialYaw
      ..pitch = widget.initialPitch
      ..distance = widget.initialDistance;
    _intro = 1;
  }

  void _onTick(Duration elapsed) {
    if (_motionOff) return;
    final delta = (elapsed - _lastElapsed).inMicroseconds / 1000000;
    _lastElapsed = elapsed;
    final dt = delta.clamp(0.0, 0.06);
    if (dt <= 0) return;

    if (_intro < 1) {
      _intro = (_intro + dt / 1.8).clamp(0.0, 1.0);
      final eased = Curves.easeOutCubic.transform(_intro);
      _camera
        ..yaw = widget.initialYaw - 0.42 * (1 - eased)
        ..pitch = (widget.initialPitch - 0.16) + 0.16 * eased
        ..distance = (widget.initialDistance + 9) - 9 * eased;
    } else if (widget.autoRotate) {
      _camera.yaw += dt * 0.075;
    }

    _runtime.time += dt;
    _adaptQuality(dt);
    _repaint.value++;
  }

  void _adaptQuality(double dt) {
    _sampleCount++;
    _averageFrame = _averageFrame * 0.94 + dt * 0.06;
    if (_sampleCount < 40 || !widget.highQuality) return;
    if (_averageFrame > 0.033 && _runtime.quality > 0.55) {
      _runtime.quality = 0.55;
      _sampleCount = 0;
    } else if (_averageFrame > 0.023 && _runtime.quality > 0.72) {
      _runtime.quality = 0.72;
      _sampleCount = 0;
    } else if (_averageFrame < 0.017 && _runtime.quality < 1) {
      _runtime.quality = math.min(1, _runtime.quality + 0.1);
      _sampleCount = 0;
    }
  }

  void _handleTap(TapUpDetails details) {
    if (!widget.interactive) return;
    HotspotProjection? best;
    var bestDistance = 34.0;
    for (final hotspot in _interaction.hotspots) {
      final distance = (hotspot.offset - details.localPosition).distance;
      if (distance < bestDistance) {
        bestDistance = distance;
        best = hotspot;
      }
    }
    if (best != null) {
      widget.onHotspotTap?.call(best.hotspot);
    }
  }

  void _handleScaleStart(ScaleStartDetails details) {
    if (!widget.interactive) return;
    _intro = 1;
    _startDistance = _camera.distance;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (!widget.interactive) return;
    if (details.pointerCount >= 2) {
      if (widget.allowZoom) {
        _camera.distance = (_startDistance / details.scale)
            .clamp(_camera.minDistance, _camera.maxDistance);
      }
    } else {
      _camera.orbitBy(details.focalPointDelta.dx, details.focalPointDelta.dy);
    }
    _repaint.value++;
  }

  void _handleScroll(PointerScrollEvent event) {
    if (!widget.interactive || !widget.allowZoom) return;
    _intro = 1;
    _camera.zoomBy(event.scrollDelta.dy > 0 ? 1.07 : 0.93);
    _repaint.value++;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final painter = TfScenePainter(
      builder: widget.builder,
      telemetry: widget.telemetry,
      camera: _camera,
      interaction: _interaction,
      runtime: _runtime,
      repaint: _repaint,
    );

    return Semantics(
      label: widget.semanticLabel,
      image: true,
      child: MouseRegion(
        cursor: widget.interactive
            ? SystemMouseCursors.grab
            : SystemMouseCursors.basic,
        child: Listener(
          onPointerSignal: (event) {
            if (event is PointerScrollEvent) _handleScroll(event);
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: _handleTap,
            onDoubleTap: () {
              _setFinalCamera();
              _repaint.value++;
            },
            onScaleStart: _handleScaleStart,
            onScaleUpdate: _handleScaleUpdate,
            child: RepaintBoundary(
              child: CustomPaint(
                painter: painter,
                isComplex: true,
                willChange: !_motionOff,
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

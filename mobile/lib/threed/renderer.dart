import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/design.dart';
import 'mesh.dart';
import 'vector.dart';

class SceneTelemetry {
  const SceneTelemetry({
    this.soil = 42,
    this.soil1,
    this.soil2,
    this.forecastSoil,
    this.battSoc = 72,
    this.genW = 64,
    this.loadW = 18,
    this.temp = 27,
    this.hum = 68,
    this.rain = 0,
    this.flow = 0,
    this.trustLevel = 'Green',
    this.trustScore = 92,
    this.energyMode = 'CHARGING',
    this.advice = 'No irrigation needed',
    this.irrigate = false,
    this.online = true,
  });

  final double soil;
  final double? soil1;
  final double? soil2;
  final double? forecastSoil;
  final double battSoc;
  final double genW;
  final double loadW;
  final double temp;
  final double hum;
  final double rain;
  final double flow;
  final String trustLevel;
  final double trustScore;
  final String energyMode;
  final String advice;
  final bool irrigate;
  final bool online;

  Color get indicatorColor => trustColor(trustLevel);
}

class Particle3D {
  const Particle3D(
      {required this.position,
      required this.size,
      required this.color,
      this.glow = 1});

  final Vec3 position;
  final double size;
  final Color color;
  final double glow;
}

class Hotspot3D {
  const Hotspot3D({
    required this.id,
    required this.position,
    required this.title,
    required this.value,
    required this.color,
  });

  final String id;
  final Vec3 position;
  final String title;
  final String value;
  final Color color;
}

class HotspotProjection {
  const HotspotProjection(
      {required this.hotspot, required this.offset, required this.depth});

  final Hotspot3D hotspot;
  final Offset offset;
  final double depth;
}

class ScenePulse {
  const ScenePulse(
      {required this.center,
      required this.radius,
      required this.color,
      this.speed = 1});

  final Vec3 center;
  final double radius;
  final Color color;
  final double speed;
}

class SceneGeometry {
  const SceneGeometry({
    required this.objects,
    this.hotspots = const [],
    this.particles = const [],
    this.pulses = const [],
    this.accent = TfColors.mint,
    this.fogColor = const Color(0xFF071412),
    this.fogDensity = 0.018,
    this.showBackdrop = true,
  });

  final List<RenderObject3D> objects;
  final List<Hotspot3D> hotspots;
  final List<Particle3D> particles;
  final List<ScenePulse> pulses;
  final Color accent;
  final Color fogColor;
  final double fogDensity;
  final bool showBackdrop;
}

typedef SceneWorldBuilder = SceneGeometry Function(SceneBuildInput input);

class SceneBuildInput {
  const SceneBuildInput(
      {required this.time, required this.quality, required this.telemetry});

  final double time;
  final double quality;
  final SceneTelemetry telemetry;
}

class SceneInteraction {
  List<HotspotProjection> hotspots = const [];
}

class SceneRuntime {
  double time = 0;
  double quality = 1;
  bool showLabels = true;
  bool compactLabels = false;
}

class TfScenePainter extends CustomPainter {
  TfScenePainter({
    required this.builder,
    required this.telemetry,
    required this.camera,
    required this.interaction,
    required this.runtime,
    required this.repaint,
  }) : super(repaint: repaint);

  final SceneWorldBuilder builder;
  final SceneTelemetry telemetry;
  final OrbitCamera camera;
  final SceneInteraction interaction;
  final SceneRuntime runtime;
  final Listenable repaint;

  double get time => runtime.time;
  double get quality => runtime.quality;
  bool get showLabels => runtime.showLabels;
  bool get compactLabels => runtime.compactLabels;

  static final List<Offset> _stars = _makeStars();

  static List<Offset> _makeStars() {
    final random = math.Random(7);
    return List.generate(
        90, (_) => Offset(random.nextDouble(), random.nextDouble() * 0.72));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final geometry = builder(
        SceneBuildInput(time: time, quality: quality, telemetry: telemetry));
    _paintBackdrop(canvas, size, geometry);
    _paintShadows(canvas, size, geometry);
    final projected = _paintMeshes(canvas, size, geometry);
    _paintParticles(canvas, size, geometry);
    _paintPulses(canvas, size, geometry);
    _paintHotspots(canvas, size, geometry, projected);
    _paintVignette(canvas, size, geometry);
  }

  void _paintBackdrop(Canvas canvas, Size size, SceneGeometry geometry) {
    if (geometry.showBackdrop) {
      final background = Paint()
        ..shader = ui.Gradient.radial(
          Offset(size.width * 0.55, size.height * 0.28),
          size.longestSide * 0.95,
          [
            mixColor(TfColors.ink2, geometry.accent, 0.10),
            TfColors.ink2,
            TfColors.ink,
          ],
          [0, 0.55, 1],
        );
      canvas.drawRect(Offset.zero & size, background);

      final skyGlow = Paint()
        ..shader = ui.Gradient.radial(
          Offset(size.width * 0.72, size.height * 0.2),
          size.shortestSide * 0.72,
          [
            geometry.accent.withValues(alpha: 0.16),
            geometry.accent.withValues(alpha: 0)
          ],
        );
      canvas.drawRect(Offset.zero & size, skyGlow);

      final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.24);
      for (var i = 0; i < _stars.length; i++) {
        final star = _stars[i];
        final twinkle =
            0.35 + 0.65 * (0.5 + 0.5 * math.sin(time * 0.9 + i * 1.7));
        starPaint.color = Colors.white.withValues(alpha: 0.08 + 0.16 * twinkle);
        canvas.drawCircle(
          Offset(star.dx * size.width, star.dy * size.height),
          i % 7 == 0 ? 1.2 : 0.7,
          starPaint,
        );
      }

      final beam = Paint()
        ..shader = ui.Gradient.linear(
          Offset(size.width * 0.24, -20),
          Offset(size.width * 0.78, size.height),
          [geometry.accent.withValues(alpha: 0.06), Colors.transparent],
        );
      final beamPath = Path()
        ..moveTo(size.width * 0.05, 0)
        ..lineTo(size.width * 0.38, 0)
        ..lineTo(size.width * 0.88, size.height)
        ..lineTo(size.width * 0.45, size.height)
        ..close();
      canvas.drawPath(beamPath, beam);
    }
  }

  void _paintShadows(Canvas canvas, Size size, SceneGeometry geometry) {
    for (final object in geometry.objects) {
      if (!object.castShadow) continue;
      final ground = Vec3(object.position.x, 0.04, object.position.z);
      final projected = camera.project(ground, size);
      if (projected == null) continue;
      final radius = object.shadowRadius * projected.scale * 1.6;
      if (radius < 2) continue;
      final paint = Paint()
        ..shader = ui.Gradient.radial(
          Offset.zero,
          math.max(radius, 8),
          [
            Colors.black.withValues(alpha: 0.34),
            Colors.black.withValues(alpha: 0)
          ],
          [0, 1],
        );
      canvas.save();
      canvas.translate(projected.offset.dx, projected.offset.dy);
      canvas.scale(1.0, 0.3);
      canvas.drawCircle(Offset.zero, radius, paint);
      canvas.restore();
    }
  }

  List<HotspotProjection> _paintMeshes(
      Canvas canvas, Size size, SceneGeometry geometry) {
    final eye = camera.position;
    final forward = (camera.target - eye).normalized;
    final worldUp = const Vec3(0, 1, 0);
    var right = forward.cross(worldUp).normalized;
    if (right.length < 0.001) right = const Vec3(1, 0, 0);
    final up = right.cross(forward).normalized;
    final focal = (size.height * 0.5) / math.tan(camera.fovY * 0.5);

    final keyLight = const Vec3(-0.52, 0.82, 0.45).normalized;
    final fillLight = const Vec3(0.72, 0.38, -0.55).normalized;
    final rimBase = geometry.accent;
    final fog = geometry.fogColor;
    final fogDensity = geometry.fogDensity;

    final triangles = <_ProjectedTriangle>[];
    final projectedHotspots = <HotspotProjection>[];
    final vertexCache = <Vec3, _ProjectedVertex>{};

    _ProjectedVertex project(Vec3 point) {
      final cached = vertexCache[point];
      if (cached != null) return cached;
      final relative = point - eye;
      final depth = relative.dot(forward);
      if (depth <= 0.12) {
        final result = _ProjectedVertex(null, depth);
        vertexCache[point] = result;
        return result;
      }
      final x = size.width * 0.5 + relative.dot(right) * focal / depth;
      final y = size.height * 0.5 - relative.dot(up) * focal / depth;
      final result = _ProjectedVertex(Offset(x, y), depth);
      vertexCache[point] = result;
      return result;
    }

    for (final object in geometry.objects) {
      final cosX = math.cos(object.rotation.x);
      final sinX = math.sin(object.rotation.x);
      final cosY = math.cos(object.rotation.y);
      final sinY = math.sin(object.rotation.y);
      final cosZ = math.cos(object.rotation.z);
      final sinZ = math.sin(object.rotation.z);
      final transformed = <Vec3>[];
      for (final vertex in object.mesh.vertices) {
        var x = vertex.x * object.scale.x;
        var y = vertex.y * object.scale.y;
        var z = vertex.z * object.scale.z;
        if (cosX != 1 || sinX != 0) {
          final ny = y * cosX - z * sinX;
          z = y * sinX + z * cosX;
          y = ny;
        }
        if (cosY != 1 || sinY != 0) {
          final nx = x * cosY + z * sinY;
          z = -x * sinY + z * cosY;
          x = nx;
        }
        if (cosZ != 1 || sinZ != 0) {
          final nx = x * cosZ - y * sinZ;
          y = x * sinZ + y * cosZ;
          x = nx;
        }
        transformed.add(Vec3(x + object.position.x, y + object.position.y,
            z + object.position.z));
      }

      for (final face in object.mesh.faces) {
        final a = transformed[face.a];
        final b = transformed[face.b];
        final c = transformed[face.c];
        final normal = (b - a).cross(c - a).normalized;
        final center = (a + b + c) / 3;
        final view = eye - center;
        final facing = normal.dot(view);
        if (facing <= 0 && !face.doubleSided) continue;

        final n = facing < 0 ? normal * -1 : normal;
        final lambert = math.max(0.0, n.dot(keyLight));
        final fill = math.max(0.0, n.dot(fillLight));
        final hemisphere = 0.42 + 0.22 * (n.y * 0.5 + 0.5);
        var light = hemisphere + lambert * 0.72 + fill * 0.22;

        final pa = project(a);
        final pb = project(b);
        final pc = project(c);
        if (pa.offset == null || pb.offset == null || pc.offset == null) {
          continue;
        }

        final depth = (pa.depth + pb.depth + pc.depth) / 3;
        final fogFactor = (1 - math.exp(-fogDensity * depth)).clamp(0.0, 0.82);
        final viewDir = view.normalized;
        final half = (keyLight + viewDir).normalized;
        final spec = math.pow(math.max(0.0, n.dot(half)), 26) * 0.32;
        final rim =
            math.pow(1 - math.max(0.0, n.dot(viewDir)).clamp(0.0, 1.0), 3) *
                0.22;

        final base = face.color;
        var shaded = scaleColor(base, light.clamp(0.18, 1.6));
        if (spec > 0.002) {
          shaded = _addLight(shaded, Colors.white, spec);
        }
        if (rim > 0.002) {
          shaded = _addLight(shaded, rimBase, rim);
        }
        if (face.emissive > 0) {
          shaded = mixColor(shaded, scaleColor(base, 1.25), face.emissive);
        }
        shaded = mixColor(shaded, fog, fogFactor);
        final alpha = (base.a * object.opacity).clamp(0.0, 1.0);
        final color = shaded.withValues(alpha: alpha);

        triangles.add(_ProjectedTriangle(
            pa.offset!, pb.offset!, pc.offset!, depth, color));
      }
    }

    triangles.sort((a, b) => b.depth.compareTo(a.depth));

    if (triangles.isNotEmpty) {
      final positions = Float32List(triangles.length * 6);
      final colors = Int32List(triangles.length * 3);
      var pi = 0;
      var ci = 0;
      for (final triangle in triangles) {
        positions[pi++] = triangle.a.dx;
        positions[pi++] = triangle.a.dy;
        positions[pi++] = triangle.b.dx;
        positions[pi++] = triangle.b.dy;
        positions[pi++] = triangle.c.dx;
        positions[pi++] = triangle.c.dy;
        final argb = triangle.color.toARGB32();
        colors[ci++] = argb;
        colors[ci++] = argb;
        colors[ci++] = argb;
      }
      final vertices =
          ui.Vertices.raw(ui.VertexMode.triangles, positions, colors: colors);
      final paint = Paint()
        ..isAntiAlias = true
        ..blendMode = BlendMode.srcOver;
      canvas.drawVertices(vertices, BlendMode.srcOver, paint);
      vertices.dispose();
    }

    if (showLabels) {
      for (final hotspot in geometry.hotspots) {
        final point = project(hotspot.position);
        if (point.offset == null) continue;
        projectedHotspots.add(HotspotProjection(
          hotspot: hotspot,
          offset: point.offset!,
          depth: point.depth,
        ));
      }
      projectedHotspots.sort((a, b) => a.depth.compareTo(b.depth));
    }
    interaction.hotspots = projectedHotspots;
    return projectedHotspots;
  }

  void _paintParticles(Canvas canvas, Size size, SceneGeometry geometry) {
    final eye = camera.position;
    final forward = (camera.target - eye).normalized;
    final worldUp = const Vec3(0, 1, 0);
    final right = forward.cross(worldUp).normalized;
    final up = right.cross(forward).normalized;
    final focal = (size.height * 0.5) / math.tan(camera.fovY * 0.5);

    for (final particle in geometry.particles) {
      final relative = particle.position - eye;
      final depth = relative.dot(forward);
      if (depth <= 0.5) continue;
      final x = size.width * 0.5 + relative.dot(right) * focal / depth;
      final y = size.height * 0.5 - relative.dot(up) * focal / depth;
      final radius = (particle.size * focal / depth).clamp(0.5, 18.0);
      final alpha = (particle.color.a *
              (1 - (depth / (camera.distance * 2.4))).clamp(0.0, 1.0) *
              particle.glow)
          .clamp(0.0, 1.0);
      if (alpha <= 0.01) continue;
      final glow = Paint()
        ..blendMode = BlendMode.plus
        ..shader = ui.Gradient.radial(
          Offset(x, y),
          radius * 3.4,
          [
            particle.color.withValues(alpha: alpha * 0.55),
            particle.color.withValues(alpha: 0)
          ],
        );
      canvas.drawCircle(Offset(x, y), radius * 3.4, glow);
      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()
          ..color = Colors.white.withValues(alpha: alpha * 0.9)
          ..blendMode = BlendMode.plus,
      );
    }
  }

  void _paintPulses(Canvas canvas, Size size, SceneGeometry geometry) {
    for (final pulse in geometry.pulses) {
      final projected = camera.project(pulse.center, size);
      if (projected == null) continue;
      for (var i = 0; i < 2; i++) {
        final phase = ((time * pulse.speed + i * 0.5) % 1.0);
        final radius = pulse.radius * projected.scale * (0.4 + phase * 1.6);
        final alpha = (1 - phase) * 0.32;
        if (alpha <= 0) continue;
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..blendMode = BlendMode.plus
          ..color = pulse.color.withValues(alpha: alpha);
        canvas.drawOval(
          Rect.fromCenter(
              center: projected.offset,
              width: radius * 2,
              height: radius * 0.8),
          paint,
        );
      }
    }
  }

  void _paintHotspots(Canvas canvas, Size size, SceneGeometry geometry,
      List<HotspotProjection> hotspots) {
    if (!showLabels) return;
    final usedRects = <Rect>[];
    for (final entry in hotspots) {
      final hotspot = entry.hotspot;
      final dot = entry.offset;
      if (dot.dx < -30 ||
          dot.dx > size.width + 30 ||
          dot.dy < -20 ||
          dot.dy > size.height + 20) {
        continue;
      }

      final glow = Paint()
        ..blendMode = BlendMode.plus
        ..shader = ui.Gradient.radial(
          dot,
          compactLabels ? 18 : 26,
          [
            hotspot.color.withValues(alpha: 0.45),
            hotspot.color.withValues(alpha: 0)
          ],
        );
      canvas.drawCircle(dot, compactLabels ? 18 : 26, glow);
      canvas.drawCircle(
          dot, compactLabels ? 2.6 : 3.4, Paint()..color = hotspot.color);
      canvas.drawCircle(
        dot,
        compactLabels ? 6.5 : 8.5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1
          ..color = hotspot.color.withValues(alpha: 0.55),
      );

      if (!compactLabels) {
        final title = TextPainter(
          text: TextSpan(
            text: hotspot.title.toUpperCase(),
            style: TfType.label(
                color: TfColors.text.withValues(alpha: 0.85), size: 8.5),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout();
        final value = TextPainter(
          text: TextSpan(
            text: hotspot.value,
            style: TfType.title(11.5, color: TfColors.text)
                .copyWith(fontSize: 11.5),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout(maxWidth: 150);

        final padding = compactLabels ? 6.0 : 9.0;
        final chipWidth = math.max(title.width, value.width) + padding * 2;
        final chipHeight = title.height + value.height + padding * 2 + 3;
        var left = dot.dx + 16;
        var top = dot.dy - chipHeight / 2;
        if (left + chipWidth > size.width - 8) {
          left = dot.dx - chipWidth - 16;
        }
        top = top.clamp(8.0, math.max(8.0, size.height - chipHeight - 8));

        var rect = Rect.fromLTWH(left, top, chipWidth, chipHeight);
        var attempts = 0;
        while (usedRects.any((used) => used.overlaps(rect.inflate(2))) &&
            attempts < 4) {
          rect = rect.translate(0, chipHeight + 6);
          if (rect.bottom > size.height - 8) {
            rect = Rect.fromLTWH(
                rect.left,
                math.max(8, top - (attempts + 1) * (chipHeight + 6)),
                chipWidth,
                chipHeight);
          }
          attempts++;
        }
        usedRects.add(rect);

        canvas.drawLine(
          dot,
          Offset(rect.left < dot.dx ? rect.right : rect.left, rect.center.dy),
          Paint()
            ..color = hotspot.color.withValues(alpha: 0.35)
            ..strokeWidth = 0.9,
        );
        final chipPaint = Paint()
          ..shader = ui.Gradient.linear(
            rect.topLeft,
            rect.bottomRight,
            [const Color(0xE60A1718), const Color(0xB30A1718)],
          );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(10)),
          chipPaint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(10)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8
            ..color = hotspot.color.withValues(alpha: 0.28),
        );
        title.paint(
            canvas, Offset(rect.left + padding, rect.top + padding - 1));
        value.paint(canvas,
            Offset(rect.left + padding, rect.top + padding + title.height + 2));
      }
    }
  }

  void _paintVignette(Canvas canvas, Size size, SceneGeometry geometry) {
    final bottom = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, size.height * 0.68),
        Offset(0, size.height),
        [Colors.transparent, TfColors.ink.withValues(alpha: 0.55)],
      );
    canvas.drawRect(Offset.zero & size, bottom);

    final top = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(0, size.height * 0.22),
        [TfColors.ink.withValues(alpha: 0.42), Colors.transparent],
      );
    canvas.drawRect(Offset.zero & size, top);

    final edge = Paint()
      ..shader = ui.Gradient.radial(
        size.center(Offset.zero),
        size.longestSide * 0.72,
        [Colors.transparent, TfColors.ink.withValues(alpha: 0.32)],
        [0.6, 1],
      );
    canvas.drawRect(Offset.zero & size, edge);
  }

  Color _addLight(Color base, Color light, double amount) {
    final a = amount.clamp(0.0, 1.0);
    final r = (base.r * 255 + light.r * 255 * a).clamp(0, 255).round();
    final g = (base.g * 255 + light.g * 255 * a).clamp(0, 255).round();
    final b = (base.b * 255 + light.b * 255 * a).clamp(0, 255).round();
    return Color.fromARGB((base.a * 255).round(), r, g, b);
  }

  @override
  bool shouldRepaint(covariant TfScenePainter oldDelegate) {
    return oldDelegate.telemetry != telemetry ||
        oldDelegate.runtime != runtime ||
        oldDelegate.builder != builder;
  }
}

class _ProjectedVertex {
  const _ProjectedVertex(this.offset, this.depth);

  final Offset? offset;
  final double depth;
}

class _ProjectedTriangle {
  const _ProjectedTriangle(this.a, this.b, this.c, this.depth, this.color);

  final Offset a;
  final Offset b;
  final Offset c;
  final double depth;
  final Color color;
}

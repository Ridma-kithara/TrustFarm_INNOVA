import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/design.dart';
import '../../core/formatters.dart';
import '../mesh.dart';
import '../renderer.dart';
import '../vector.dart';

/// The signature TrustFarm experience: a living digital twin of a monitored
/// zone built from real geometry, lit and animated in real time.
///
/// Every structure maps to a real part of the system described in the project
/// documentation: soil probes, the ESP32 node, rain gauge, waste-to-energy
/// digester, generator, battery, irrigation line and the crop bed.
SceneGeometry buildFarmScene(SceneBuildInput input) {
  final telemetry = input.telemetry;
  final time = input.time;
  final quality = input.quality;
  final moisture = (telemetry.soil / 100).clamp(0.0, 1.0);
  final trust = telemetry.indicatorColor;
  final online = telemetry.online;
  final rain = telemetry.rain > 0;
  final flow = telemetry.flow + (telemetry.irrigate ? 4.2 : 0);
  final energyColor = switch (telemetry.energyMode.toUpperCase()) {
    'PROTECT' => TfColors.red,
    'CONSERVE' => TfColors.amber,
    'CHARGING' => TfColors.green,
    _ => TfColors.cyan,
  };

  final objects = <RenderObject3D>[];
  final particles = <Particle3D>[];
  final pulses = <ScenePulse>[];
  final hotspots = <Hotspot3D>[];

  const groundY = 0.38;
  final soilColor =
      Color.lerp(const Color(0xFF74583A), const Color(0xFF2E7248), moisture)!;
  final lushColor =
      Color.lerp(const Color(0xFF8B8A46), const Color(0xFF3CC97A), moisture)!;
  final platformTop =
      Color.lerp(const Color(0xFF18342C), const Color(0xFF1D3B31), moisture)!;

  // ---------------------------------------------------------------- platform
  objects.add(RenderObject3D(
    mesh: Mesh3()
      ..box(
        center: const Vec3(0, 0.12, 0),
        size: const Vec3(17.2, 0.36, 13.2),
        color: const Color(0xFF0C1A18),
        topColor: const Color(0xFF10231F),
      )
      ..box(
        center: const Vec3(0, 0.28, 0),
        size: const Vec3(16.4, 0.18, 12.4),
        color: const Color(0xFF132B25),
        topColor: platformTop,
      ),
    position: Vec3.zero,
    castShadow: false,
  ));

  // A subtle rim light that follows the trust level.
  final rimMesh = Mesh3();
  const rimY = 0.39;
  final rimColor = trust.withValues(alpha: 0.55);
  rimMesh.beam(
      a: const Vec3(-8.0, rimY, 6.1),
      b: const Vec3(8.0, rimY, 6.1),
      thickness: 0.045,
      color: rimColor,
      emissive: 0.8);
  rimMesh.beam(
      a: const Vec3(-8.0, rimY, -6.1),
      b: const Vec3(8.0, rimY, -6.1),
      thickness: 0.045,
      color: rimColor,
      emissive: 0.8);
  rimMesh.beam(
      a: const Vec3(-8.0, rimY, -6.1),
      b: const Vec3(-8.0, rimY, 6.1),
      thickness: 0.045,
      color: rimColor,
      emissive: 0.8);
  rimMesh.beam(
      a: const Vec3(8.0, rimY, -6.1),
      b: const Vec3(8.0, rimY, 6.1),
      thickness: 0.045,
      color: rimColor,
      emissive: 0.8);
  objects.add(RenderObject3D(mesh: rimMesh, castShadow: false));

  // -------------------------------------------------------------- crop field
  final field = Mesh3();
  const cols = 9;
  const rows = 7;
  final cellX = 8.2 / cols;
  final cellZ = 6.6 / rows;
  const fieldLeft = -6.7;
  const fieldFront = -3.5;
  for (var x = 0; x < cols; x++) {
    for (var z = 0; z < rows; z++) {
      final x0 = fieldLeft + x * cellX;
      final z0 = fieldFront + z * cellZ;
      final noise = math.sin((x + 1) * 1.7 + z * 0.8) * 0.035 +
          math.cos(x * 0.9 - z * 1.4) * 0.025;
      final y = groundY + noise;
      final variation = 0.86 + 0.22 * (0.5 + 0.5 * math.sin(x * 2.3 + z * 1.1));
      final color = mixColor(soilColor, lushColor, (moisture * 0.55))
          .withValues(alpha: 1);
      final shaded = scaleColor(color, variation);
      field.quad(
        Vec3(x0, y, z0),
        Vec3(x0 + cellX * 0.98, y, z0),
        Vec3(x0 + cellX * 0.98, y, z0 + cellZ * 0.98),
        Vec3(x0, y, z0 + cellZ * 0.98),
        rain ? mixColor(shaded, const Color(0xFF235566), 0.24) : shaded,
        outward: const Vec3(0, 10, 0),
        doubleSided: false,
      );
    }
  }

  // Farrow lines across the bed.
  for (var z = 1; z < rows; z += 2) {
    final zLine = fieldFront + z * cellZ;
    field.beam(
      a: Vec3(fieldLeft + 0.05, groundY + 0.04, zLine),
      b: Vec3(fieldLeft + 8.15, groundY + 0.04, zLine),
      thickness: 0.025,
      color: const Color(0x55233B2E),
    );
  }
  objects.add(RenderObject3D(mesh: field, castShadow: false));

  // Crops: real leaf geometry, taller and greener when moisture is healthy.
  final crops = Mesh3();
  final plantCount = quality > 0.8 ? 16 : 10;
  for (var i = 0; i < plantCount; i++) {
    final column = i % 4;
    final row = i ~/ 4;
    final x = fieldLeft + 1.0 + column * 2.0 + math.sin(i * 1.7) * 0.28;
    final z = fieldFront + 1.0 + row * 1.7 + math.cos(i * 1.3) * 0.24;
    final base = Vec3(x, groundY + 0.05, z);
    final height = 0.48 + moisture * 0.65 + math.sin(i * 2.1) * 0.08;
    final stemColor =
        mixColor(const Color(0xFF78924A), const Color(0xFF41B86D), moisture);
    final leafColor = mixColor(const Color(0xFF93A24D), lushColor, moisture)
        .withValues(alpha: 0.95);
    crops.beam(
        a: base,
        b: base + Vec3(0, height, 0),
        thickness: 0.045,
        color: stemColor);
    final sway = math.sin(time * 1.3 + i) * 0.05;
    final leafDirA = Vec3(0.65 + sway, 0.45, 0.3).normalized;
    final leafDirB = Vec3(-0.55 + sway, 0.55, -0.35).normalized;
    final top = base + Vec3(0, height * 0.88, 0);
    crops.leaf(
      base: top,
      direction: leafDirA,
      length: 0.55 + moisture * 0.28,
      width: 0.18,
      color: leafColor,
      tipColor: scaleColor(leafColor, 1.2),
    );
    crops.leaf(
      base: top - Vec3(0, 0.14, 0),
      direction: leafDirB,
      length: 0.48 + moisture * 0.22,
      width: 0.16,
      color: scaleColor(leafColor, 0.92),
    );
    if (quality > 0.8 && moisture > 0.55 && i % 3 == 0) {
      crops.sphere(
        center: top + Vec3(0, 0.08, 0),
        radius: 0.07,
        color: const Color(0xFFF5D77B),
        rings: 3,
        segments: 6,
        emissive: 0.15,
      );
    }
  }
  objects.add(RenderObject3D(mesh: crops, castShadow: false));

  // ------------------------------------------------------------- ESP32 node
  const nodeX = -5.5;
  const nodeZ = -4.4;
  final node = Mesh3();
  node.beam(
    a: const Vec3(nodeX, groundY, nodeZ),
    b: const Vec3(nodeX, 2.7, nodeZ),
    thickness: 0.11,
    color: const Color(0xFF30413C),
  );
  node.beam(
    a: const Vec3(nodeX - 0.55, groundY + 0.04, nodeZ),
    b: const Vec3(nodeX, 0.7, nodeZ),
    thickness: 0.06,
    color: const Color(0xFF263A34),
  );
  node.beam(
    a: const Vec3(nodeX + 0.55, groundY + 0.04, nodeZ),
    b: const Vec3(nodeX, 0.7, nodeZ),
    thickness: 0.06,
    color: const Color(0xFF263A34),
  );
  node.box(
    center: const Vec3(nodeX, 2.45, nodeZ),
    size: const Vec3(0.82, 0.5, 0.36),
    color: const Color(0xFF1B2A26),
    topColor: const Color(0xFF273E36),
  );
  node.box(
    center: const Vec3(nodeX, 2.48, nodeZ + 0.19),
    size: const Vec3(0.36, 0.2, 0.05),
    color: const Color(0xFF0E1715),
    bottom: false,
  );
  node.box(
    center: const Vec3(nodeX - 0.24, 2.78, nodeZ),
    size: const Vec3(0.24, 0.16, 0.24),
    color: const Color(0xFF31443D),
    topColor: const Color(0xFF3C544B),
  );
  node.beam(
    a: const Vec3(nodeX + 0.3, 2.68, nodeZ),
    b: const Vec3(nodeX + 0.38, 3.55, nodeZ - 0.04),
    thickness: 0.025,
    color: const Color(0xFF5A756C),
  );
  node.sphere(
    center: Vec3(nodeX + 0.3, 2.56, nodeZ + 0.23),
    radius: 0.055,
    color: online ? trust : TfColors.grey,
    rings: 3,
    segments: 6,
    emissive: 1,
  );
  node.ring(
    center: Vec3(nodeX, 3.15, nodeZ),
    outerRadius: 0.48,
    innerRadius: 0.43,
    color: trust.withValues(alpha: 0.65),
    segments: quality > 0.8 ? 28 : 16,
    emissive: 0.9,
  );
  node.ring(
    center: Vec3(nodeX, 3.15, nodeZ),
    outerRadius: 0.32,
    innerRadius: 0.29,
    color: TfColors.cyan.withValues(alpha: 0.4),
    segments: quality > 0.8 ? 24 : 14,
    vertical: true,
    emissive: 0.7,
  );
  objects.add(RenderObject3D(
    mesh: node,
    castShadow: true,
    shadowRadius: 0.8,
  ));

  pulses.add(ScenePulse(
      center: Vec3(nodeX, 3.15, nodeZ),
      radius: 0.9,
      color: trust,
      speed: 0.55));
  pulses.add(ScenePulse(
      center: Vec3(nodeX, 3.15, nodeZ),
      radius: 0.55,
      color: TfColors.cyan,
      speed: 0.85));

  // Soil probes and their signal lines.
  final probeMesh = Mesh3();
  final probeSpots = [
    (
      position: const Vec3(-3.7, groundY, 1.2),
      value: telemetry.soil1 ?? telemetry.soil,
      color: TfColors.cyan
    ),
    (
      position: const Vec3(-1.2, groundY, 2.5),
      value: telemetry.soil2 ?? telemetry.soil,
      color: TfColors.mint
    ),
  ];
  for (final spot in probeSpots) {
    final probeColor = mixColor(const Color(0xFF6D8D84), spot.color, 0.35);
    probeMesh.cylinder(
      base: spot.position,
      radius: 0.075,
      height: 0.66,
      color: probeColor,
      segments: 8,
      topColor: const Color(0xFFBCD7CD),
      emissive: 0.15,
    );
    probeMesh.sphere(
      center: spot.position + const Vec3(0, 0.7, 0),
      radius: 0.1,
      color: spot.color,
      rings: 3,
      segments: 8,
      emissive: 1,
    );
    probeMesh.ring(
      center: spot.position + const Vec3(0, 0.02, 0),
      outerRadius: 0.32,
      innerRadius: 0.27,
      color: spot.color.withValues(alpha: 0.5),
      segments: 18,
      emissive: 0.6,
    );
    probeMesh.beam(
      a: spot.position + const Vec3(0, 0.04, 0),
      b: Vec3(nodeX + 0.4, 0.5, nodeZ + 0.4),
      thickness: 0.022,
      color: const Color(0xFF2C4C44),
    );
    pulses.add(ScenePulse(
        center: spot.position + const Vec3(0, 0.7, 0),
        radius: 0.36,
        color: spot.color,
        speed: 1.2));
    hotspots.add(Hotspot3D(
      id: 'soil',
      position: spot.position + const Vec3(0, 1.15, 0),
      title: 'Soil probes',
      value: '${formatSoil(spot.value)} moisture',
      color: spot.color,
    ));
    // Sensor data travelling to the node.
    if (online) {
      for (var i = 0; i < 3; i++) {
        final t = (time * 0.3 + i / 3) % 1;
        final path = _lerp3(spot.position + const Vec3(0, 0.5, 0),
            Vec3(nodeX + 0.4, 0.6, nodeZ + 0.4), t);
        particles.add(Particle3D(
            position: path, size: 0.035, color: spot.color, glow: 0.8));
      }
    }
  }
  objects.add(RenderObject3D(mesh: probeMesh, castShadow: false));

  // Rain gauge near the node.
  final rainGauge = Mesh3();
  rainGauge.beam(
    a: const Vec3(-6.4, groundY, -2.4),
    b: const Vec3(-6.4, 1.45, -2.4),
    thickness: 0.06,
    color: const Color(0xFF3A4A44),
  );
  rainGauge.cylinder(
    base: const Vec3(-6.4, 1.35, -2.4),
    radius: 0.32,
    height: 0.12,
    color: const Color(0xFF214246),
    segments: 14,
    topColor: rain ? const Color(0xFF3F8EA0) : const Color(0xFF2C5157),
  );
  rainGauge.ring(
    center: const Vec3(-6.4, 1.49, -2.4),
    outerRadius: 0.29,
    innerRadius: 0.24,
    color: TfColors.cyan.withValues(alpha: 0.55),
    segments: 16,
    emissive: 0.8,
  );
  objects.add(RenderObject3D(mesh: rainGauge, castShadow: false));

  // ------------------------------------------------------- solar panel array
  final solar = Mesh3();
  const panelCenterX = 5.5;
  const panelCenterZ = -3.6;
  solar.beam(
    a: const Vec3(panelCenterX - 1.2, groundY, panelCenterZ),
    b: const Vec3(panelCenterX - 1.2, 1.75, panelCenterZ),
    thickness: 0.09,
    color: const Color(0xFF344740),
  );
  solar.beam(
    a: const Vec3(panelCenterX + 1.2, groundY, panelCenterZ),
    b: const Vec3(panelCenterX + 1.2, 1.75, panelCenterZ),
    thickness: 0.09,
    color: const Color(0xFF344740),
  );
  final panelRotation = Vec3(-0.55, 0.28, 0);
  solar.box(
    center: const Vec3(panelCenterX, 2.15, panelCenterZ),
    size: const Vec3(3.9, 1.7, 0.09),
    color: const Color(0xFF0A2030),
    topColor: const Color(0xFF0E3448),
    rotation: panelRotation,
  );
  Vec3 panelPoint(double x, double y) {
    return Vec3(x * 1.95, y * 0.85, 0.065)
            .rotateX(panelRotation.x)
            .rotateY(panelRotation.y) +
        const Vec3(panelCenterX, 2.15, panelCenterZ);
  }

  for (var i = 1; i < 4; i++) {
    final fx = -1 + i * 0.5;
    solar.beam(
      a: panelPoint(fx, -0.96),
      b: panelPoint(fx, 0.96),
      thickness: 0.013,
      color: const Color(0xFF2D6F8B),
      emissive: 0.4,
    );
  }
  for (var i = 1; i < 3; i++) {
    final fy = -1 + i * (2 / 3);
    solar.beam(
      a: panelPoint(-0.96, fy),
      b: panelPoint(0.96, fy),
      thickness: 0.013,
      color: const Color(0xFF2D6F8B),
      emissive: 0.4,
    );
  }
  solar.quad(
    panelPoint(-0.74, 0.7),
    panelPoint(-0.2, 0.7),
    panelPoint(-0.2, 0.94),
    panelPoint(-0.74, 0.94),
    Colors.white.withValues(alpha: 0.09),
    doubleSided: true,
  );
  objects.add(RenderObject3D(mesh: solar, castShadow: true, shadowRadius: 2.2));

  // ------------------------------------------------------ biogas + generator
  final energy = Mesh3();
  const digesterX = 6.3;
  const digesterZ = 2.0;
  energy.cylinder(
    base: const Vec3(digesterX, groundY, digesterZ),
    radius: 1.45,
    height: 1.0,
    color: const Color(0xFF2C5648),
    topColor: const Color(0xFF376B57),
    segments: quality > 0.8 ? 18 : 12,
  );
  energy.ring(
    center: const Vec3(digesterX, groundY + 0.52, digesterZ),
    outerRadius: 1.47,
    innerRadius: 1.37,
    color: const Color(0xFF4B8C70),
    segments: quality > 0.8 ? 20 : 12,
    emissive: 0.1,
  );
  energy.dome(
    center: const Vec3(digesterX, groundY + 1.0, digesterZ),
    radius: 1.45,
    color: const Color(0xFF43876A),
    rings: quality > 0.8 ? 5 : 3,
    segments: quality > 0.8 ? 18 : 12,
    squashY: 0.72,
  );
  energy.beam(
    a: const Vec3(digesterX + 0.1, groundY + 1.9, digesterZ),
    b: const Vec3(digesterX - 1.2, groundY + 1.35, digesterZ - 0.4),
    thickness: 0.07,
    color: const Color(0xFF5A7268),
  );
  // Organic waste inlet.
  energy.box(
    center: const Vec3(digesterX + 1.7, groundY + 0.3, digesterZ + 1.2),
    size: const Vec3(0.9, 0.55, 0.7),
    color: const Color(0xFF5B4A33),
    topColor: const Color(0xFF75603F),
  );
  energy.beam(
    a: const Vec3(digesterX + 1.7, groundY + 0.58, digesterZ + 1.2),
    b: const Vec3(digesterX + 1.0, groundY + 0.85, digesterZ + 0.8),
    thickness: 0.12,
    color: const Color(0xFF4C4B3C),
  );

  // Generator with an animated flywheel.
  const genX = 4.5;
  const genZ = 3.1;
  energy.box(
    center: const Vec3(genX, groundY + 0.45, genZ),
    size: const Vec3(1.25, 0.9, 0.85),
    color: const Color(0xFF24322E),
    topColor: const Color(0xFF35463F),
  );
  energy.box(
    center: const Vec3(genX, groundY + 0.45, genZ + 0.44),
    size: const Vec3(0.72, 0.35, 0.03),
    color: const Color(0xFF111B18),
    bottom: false,
  );
  energy.beam(
    a: const Vec3(digesterX - 0.2, groundY + 1.45, digesterZ - 0.3),
    b: const Vec3(genX + 0.2, groundY + 0.85, genZ),
    thickness: 0.06,
    color: const Color(0xFF5A7268),
  );
  final speed = telemetry.genW > 1 ? 6.5 : 0.3;
  for (var i = 0; i < 3; i++) {
    final angle = time * speed + i * (math.pi * 2 / 3);
    final center = Vec3(genX + 0.12, groundY + 0.5, genZ + 0.47);
    final tip = center + Vec3(math.cos(angle) * 0.3, math.sin(angle) * 0.3, 0);
    energy.beam(
        a: center, b: tip, thickness: 0.04, color: const Color(0xFF82A296));
  }
  energy.sphere(
    center: Vec3(genX - 0.4, groundY + 0.75, genZ + 0.44),
    radius: 0.055,
    color: telemetry.genW > 1 ? TfColors.green : TfColors.grey,
    rings: 3,
    segments: 6,
    emissive: 1,
  );
  objects.add(RenderObject3D(mesh: energy, castShadow: true, shadowRadius: 3));

  // ---------------------------------------------------------------- battery
  final battery = Mesh3();
  const batteryX = 4.7;
  const batteryZ = 0.0;
  battery.box(
    center: const Vec3(batteryX, groundY + 0.55, batteryZ),
    size: const Vec3(1.35, 1.1, 0.85),
    color: const Color(0xFF1F2C29),
    topColor: const Color(0xFF2C3D37),
  );
  battery.box(
    center: const Vec3(batteryX, groundY + 1.12, batteryZ),
    size: const Vec3(0.5, 0.1, 0.18),
    color: const Color(0xFF576A61),
    bottom: false,
  );
  final bars = 5;
  final litBars = ((telemetry.battSoc / 100) * bars).round().clamp(0, bars);
  for (var i = 0; i < bars; i++) {
    final lit = i < litBars;
    battery.box(
      center:
          Vec3(batteryX - 0.44 + i * 0.22, groundY + 0.42, batteryZ + 0.435),
      size: const Vec3(0.14, 0.34, 0.025),
      color: lit
          ? (telemetry.battSoc < 20
              ? TfColors.red
              : telemetry.battSoc < 40
                  ? TfColors.amber
                  : TfColors.mint)
          : const Color(0xFF263833),
      emissive: lit ? 0.8 : 0,
      bottom: false,
    );
  }
  battery.sphere(
    center: Vec3(batteryX + 0.37, groundY + 0.94, batteryZ + 0.44),
    radius: 0.05,
    color: energyColor,
    rings: 3,
    segments: 6,
    emissive: 1,
  );
  battery.beam(
    a: Vec3(genX - 0.6, groundY + 0.4, genZ - 0.2),
    b: Vec3(batteryX + 0.1, groundY + 0.4, batteryZ + 0.4),
    thickness: 0.055,
    color: const Color(0xFF2F4B40),
  );
  objects
      .add(RenderObject3D(mesh: battery, castShadow: true, shadowRadius: 1.8));

  // --------------------------------------------------------------- irrigation
  final irrigation = Mesh3();
  const pumpX = 2.0;
  const pumpZ = 4.5;
  irrigation.box(
    center: const Vec3(pumpX, groundY + 0.28, pumpZ),
    size: const Vec3(0.85, 0.55, 0.65),
    color: const Color(0xFF24413B),
    topColor: const Color(0xFF335A4F),
  );
  irrigation.beam(
    a: const Vec3(pumpX, groundY + 0.2, pumpZ - 0.3),
    b: const Vec3(1.0, groundY + 0.2, 2.4),
    thickness: 0.09,
    color: const Color(0xFF3B5B51),
  );
  irrigation.beam(
    a: const Vec3(batteryX - 0.5, groundY + 0.32, batteryZ + 0.4),
    b: Vec3(pumpX + 0.25, groundY + 0.32, pumpZ - 0.1),
    thickness: 0.05,
    color: const Color(0xFF2F4B40),
  );
  final watering = flow > 0.1;
  irrigation.beam(
    a: const Vec3(pumpX, groundY + 0.6, pumpZ),
    b: const Vec3(pumpX, groundY + 0.95, pumpZ),
    thickness: 0.08,
    color: watering ? TfColors.cyan : const Color(0xFF3B5B51),
    emissive: watering ? 0.6 : 0,
  );
  if (watering) {
    for (var i = 0; i < 8; i++) {
      final t = (time * 0.8 + i / 8) % 1;
      final path = _lerp3(Vec3(pumpX, groundY + 0.92, pumpZ),
          const Vec3(1.0, groundY + 0.3, 2.4), t);
      particles.add(Particle3D(
        position: path + Vec3(0, math.sin(t * math.pi) * 0.35, 0),
        size: 0.045,
        color: TfColors.cyan,
        glow: 0.9,
      ));
    }
  }
  objects.add(
      RenderObject3D(mesh: irrigation, castShadow: true, shadowRadius: 1.2));

  // ------------------------------------------------------- energy data flow
  if (telemetry.genW > 0.5) {
    final batteryPath = <Vec3>[
      const Vec3(digesterX, groundY + 1.5, digesterZ),
      Vec3(genX + 0.2, groundY + 1.0, genZ),
      Vec3(genX - 0.6, groundY + 0.6, genZ - 0.2),
      Vec3(batteryX + 0.1, groundY + 0.6, batteryZ + 0.4),
    ];
    final pumpPath = <Vec3>[
      Vec3(batteryX - 0.5, groundY + 0.6, batteryZ + 0.4),
      Vec3(pumpX + 0.25, groundY + 0.5, pumpZ - 0.1),
    ];
    for (var i = 0; i < 3; i++) {
      final t = (time * 0.22 + i / 3) % 1;
      particles.add(Particle3D(
        position: _samplePath(batteryPath, t),
        size: 0.05,
        color: energyColor,
        glow: 1,
      ));
    }
    for (var i = 0; i < 2; i++) {
      final t = (time * 0.3 + i / 2) % 1;
      particles.add(Particle3D(
        position: _samplePath(pumpPath, t),
        size: 0.045,
        color: TfColors.mint,
        glow: 1,
      ));
    }
  }

  // ----------------------------------------------------------- rain particles
  if (rain) {
    final count = (quality > 0.8 ? 34 : 18);
    for (var i = 0; i < count; i++) {
      final seed = i * 0.618;
      final x = -6.4 + (seed * 13.7) % 13.0;
      final z = -4.0 + (seed * 7.3) % 7.5;
      final y = groundY + 5.0 * (1 - ((time * 0.65 + seed) % 1));
      particles.add(Particle3D(
        position: Vec3(x, y, z),
        size: 0.028,
        color: TfColors.cyan,
        glow: 0.55,
      ));
    }
  }

  // --------------------------------------------------------- ambient spores
  final ambientCount = (quality > 0.8 ? 34 : 16);
  for (var i = 0; i < ambientCount; i++) {
    final seed = i * 0.37;
    final angle = time * (0.08 + (i % 5) * 0.012) + seed * 6.28;
    final radius = 4.5 + (i % 7) * 1.35;
    final height =
        0.8 + (i % 9) * 0.42 + math.sin(time * 0.4 + seed * 9) * 0.24;
    final color = i % 5 == 0
        ? TfColors.gold
        : i % 3 == 0
            ? TfColors.cyan
            : TfColors.mint;
    particles.add(Particle3D(
      position: Vec3(
          math.cos(angle) * radius, height, math.sin(angle) * radius * 0.8),
      size: 0.028 + (i % 3) * 0.012,
      color: color.withValues(alpha: 0.42),
      glow: 0.6,
    ));
  }

  // Hotspots (real values, no placeholder text).
  hotspots.add(Hotspot3D(
    id: 'node',
    position: const Vec3(nodeX, 3.75, nodeZ),
    title: 'ESP32 node',
    value: online
        ? '${telemetry.trustLevel} · ${telemetry.trustScore.round()}/100'
        : 'Offline cache',
    color: trust,
  ));
  hotspots.add(Hotspot3D(
    id: 'energy',
    position: const Vec3(digesterX, 3.05, digesterZ),
    title: 'Waste-to-energy',
    value:
        '${formatPower(telemetry.genW)} · ${energyModeLabel(telemetry.energyMode)}',
    color: TfColors.gold,
  ));
  hotspots.add(Hotspot3D(
    id: 'battery',
    position: const Vec3(batteryX, 1.95, batteryZ),
    title: 'Battery',
    value:
        '${formatPercent(telemetry.battSoc)} · ${formatPower(telemetry.loadW)} load',
    color: energyColor,
  ));
  hotspots.add(Hotspot3D(
    id: 'irrigation',
    position: const Vec3(pumpX, 1.55, pumpZ),
    title: 'Irrigation line',
    value: flow > 0.1
        ? 'Flowing ${flow.toStringAsFixed(1)} L/min'
        : telemetry.advice,
    color: TfColors.cyan,
  ));

  return SceneGeometry(
    objects: objects,
    hotspots: hotspots,
    particles: particles,
    pulses: pulses,
    accent: trust,
    fogColor: const Color(0xFF071311),
    fogDensity: 0.016,
  );
}

Vec3 _lerp3(Vec3 a, Vec3 b, double t) => Vec3(
      a.x + (b.x - a.x) * t,
      a.y + (b.y - a.y) * t,
      a.z + (b.z - a.z) * t,
    );

Vec3 _samplePath(List<Vec3> points, double t) {
  if (points.length < 2) return points.isEmpty ? Vec3.zero : points.first;
  final scaled = (t.clamp(0.0, 1.0)) * (points.length - 1);
  final index = scaled.floor().clamp(0, points.length - 2);
  return _lerp3(points[index], points[index + 1], scaled - index);
}

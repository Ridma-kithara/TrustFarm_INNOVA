import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/design.dart';
import '../mesh.dart';
import '../renderer.dart';
import '../vector.dart';

/// Cinematic brand moment: a sculpted sprout held inside two orbital rings,
/// lit like a museum object. Used by the splash and as the empty-state scene.
SceneGeometry buildEmblemScene(SceneBuildInput input) {
  final time = input.time;
  final quality = input.quality;
  final bob = math.sin(time * 0.8) * 0.12;
  final objects = <RenderObject3D>[];
  final particles = <Particle3D>[];

  // Stage and floor rings.
  final stage = Mesh3();
  stage.cylinder(
    base: const Vec3(0, -0.45, 0),
    radius: 3.9,
    height: 0.42,
    color: const Color(0xFF0B1917),
    topColor: const Color(0xFF122521),
    segments: quality > 0.8 ? 44 : 26,
  );
  stage.ring(
    center: const Vec3(0, -0.02, 0),
    outerRadius: 3.95,
    innerRadius: 3.84,
    color: TfColors.mint.withValues(alpha: 0.3),
    segments: quality > 0.8 ? 48 : 28,
    emissive: 0.6,
  );
  stage.ring(
    center: const Vec3(0, -0.015, 0),
    outerRadius: 3.35,
    innerRadius: 3.31,
    color: const Color(0x334FD8F4),
    segments: quality > 0.8 ? 40 : 24,
    emissive: 0.4,
  );
  stage.ring(
    center: const Vec3(0, -0.01, 0),
    outerRadius: 2.2,
    innerRadius: 2.17,
    color: const Color(0x22F5C451),
    segments: 32,
    emissive: 0.4,
  );
  objects.add(RenderObject3D(mesh: stage, castShadow: false));

  // Base pedestal.
  final pedestal = Mesh3();
  pedestal.cylinder(
    base: const Vec3(0, 0, 0),
    radius: 1.05,
    height: 0.4,
    color: const Color(0xFF14241F),
    topColor: const Color(0xFF203A30),
    segments: 24,
  );
  pedestal.cylinder(
    base: const Vec3(0, 0.4, 0),
    radius: 0.7,
    height: 0.38,
    color: const Color(0xFF1B332A),
    topColor: const Color(0xFF2A4A3C),
    segments: 20,
  );
  objects
      .add(RenderObject3D(mesh: pedestal, castShadow: true, shadowRadius: 2.4));

  // Orbital rings.
  final orbitYaw = time * 0.24;
  final orbit = Mesh3();
  orbit.ring(
    center: Vec3.zero,
    outerRadius: 1.85,
    innerRadius: 1.79,
    color: TfColors.gold.withValues(alpha: 0.8),
    segments: 64,
    vertical: true,
    emissive: 0.8,
  );
  orbit.ring(
    center: Vec3.zero,
    outerRadius: 2.05,
    innerRadius: 2.02,
    color: TfColors.mint.withValues(alpha: 0.5),
    segments: 56,
    vertical: true,
    emissive: 0.6,
  );
  objects.add(RenderObject3D(
    mesh: orbit,
    position: Vec3(0, 2.4 + bob, 0),
    rotation: Vec3(0.18, orbitYaw, 0.32),
    castShadow: false,
  ));
  objects.add(RenderObject3D(
    mesh: orbit.copy(),
    position: Vec3(0, 2.4 + bob, 0),
    rotation: Vec3(-0.42, -orbitYaw * 0.8 + 1.1, -0.22),
    scale: const Vec3(0.82, 0.82, 0.82),
    castShadow: false,
  ));

  // Sprout sculpture.
  final sprout = Mesh3();
  sprout.beam(
    a: const Vec3(0, 0.72, 0),
    b: const Vec3(0.04, 2.85, 0),
    thickness: 0.11,
    color: const Color(0xFF3F7C5A),
  );
  sprout.leaf(
    base: Vec3(0.02, 2.0, 0),
    direction: const Vec3(0.9, 0.55, 0.25),
    length: 1.2,
    width: 0.46,
    color: const Color(0xFF4CC98A),
    bend: 0.55,
    tipColor: const Color(0xFF79E8B0),
  );
  sprout.leaf(
    base: Vec3(0.02, 2.36, 0),
    direction: const Vec3(-0.8, 0.7, -0.2),
    length: 1.0,
    width: 0.38,
    color: const Color(0xFF3BB878),
    bend: 0.6,
    tipColor: const Color(0xFF6EE3A8),
  );
  sprout.leaf(
    base: Vec3(0.03, 2.76, 0),
    direction: const Vec3(0.25, 0.95, 0.15),
    length: 0.65,
    width: 0.24,
    color: const Color(0xFF8DE8B8),
    bend: 0.35,
  );
  // Glowing seed core.
  sprout.sphere(
    center: Vec3(0.02, 2.86, 0),
    radius: 0.16,
    color: const Color(0xFFF7DC8C),
    rings: 4,
    segments: 10,
    emissive: 1,
  );
  objects.add(RenderObject3D(
    mesh: sprout,
    position: Vec3(0, 0.74 + bob * 0.4, 0),
    rotation: Vec3(0, time * 0.1, 0),
    castShadow: false,
  ));

  // Floating spores / constellation.
  final count = quality > 0.8 ? 70 : 32;
  for (var i = 0; i < count; i++) {
    final seed = i * 0.61;
    final angle = time * (0.1 + (i % 4) * 0.03) + seed * 7.3;
    final radius = 1.2 + (i % 11) * 0.31;
    final height =
        0.3 + (i % 13) * 0.28 + math.sin(time * 0.35 + seed * 8) * 0.18;
    final color = i % 4 == 0
        ? TfColors.gold
        : i % 3 == 0
            ? TfColors.mint
            : const Color(0xFFE9FFF6);
    particles.add(Particle3D(
      position: Vec3(
          math.cos(angle) * radius, height, math.sin(angle) * radius * 0.72),
      size: 0.018 + (i % 4) * 0.012,
      color: color.withValues(alpha: 0.55),
      glow: 0.8,
    ));
  }

  return SceneGeometry(
    objects: objects,
    particles: particles,
    pulses: const [
      ScenePulse(
          center: Vec3(0, 0.02, 0),
          radius: 2.6,
          color: TfColors.mint,
          speed: 0.22),
      ScenePulse(
          center: Vec3(0, 0.02, 0),
          radius: 3.4,
          color: TfColors.gold,
          speed: 0.15),
    ],
    accent: TfColors.mint,
    fogColor: const Color(0xFF061110),
    fogDensity: 0.02,
  );
}

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:trustfarm_mobile/threed/vector.dart';

void main() {
  group('Vec3', () {
    test('supports arithmetic, dot and cross products', () {
      const a = Vec3(1, 2, 3);
      const b = Vec3(4, 5, 6);
      expect((a + b).x, 5);
      expect((b - a).y, 3);
      expect((a * 2).z, 6);
      expect(a.dot(b), 32);
      final cross = a.cross(b);
      expect(cross.x, -3);
      expect(cross.y, 6);
      expect(cross.z, -3);
    });

    test('normalizes safely, even at zero length', () {
      expect(const Vec3(0, 0, 0).normalized.length, 0);
      expect(const Vec3(3, 0, 4).normalized.length, closeTo(1, 0.000001));
    });
  });

  group('OrbitCamera', () {
    test('projects the camera target to the screen centre', () {
      final camera = OrbitCamera(distance: 16, target: const Vec3(0, 1.7, 0));
      final projected = camera.project(camera.target, const Size(400, 800));
      expect(projected, isNotNull);
      expect(projected!.offset.dx, closeTo(200, 0.0001));
      expect(projected.offset.dy, closeTo(400, 0.0001));
      expect(projected.depth, closeTo(16, 0.0001));
    });

    test('rejects points behind the camera', () {
      final camera = OrbitCamera();
      final eye = camera.position;
      final behind = eye + (eye - camera.target).normalized * 4;
      expect(camera.project(behind, const Size(400, 800)), isNull);
    });

    test('orbit and zoom stay inside their limits', () {
      final camera = OrbitCamera(
          minPitch: 0.1, maxPitch: 1.0, minDistance: 8, maxDistance: 24);
      camera.orbitBy(0, 100000);
      expect(camera.pitch, 1.0);
      camera.orbitBy(0, -100000);
      expect(camera.pitch, 0.1);
      camera.zoomBy(0.001);
      expect(camera.distance, 8);
      camera.zoomBy(1000);
      expect(camera.distance, 24);
    });
  });
}

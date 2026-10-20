import 'dart:math' as math;
import 'dart:ui';

import 'vector.dart';

class Face3 {
  const Face3(this.a, this.b, this.c, this.color,
      {this.doubleSided = false, this.emissive = 0});

  final int a;
  final int b;
  final int c;
  final Color color;
  final bool doubleSided;

  /// 0 = matte, 1 = fully self-lit (LEDs, water, beacons).
  final double emissive;
}

class Mesh3 {
  Mesh3();

  final List<Vec3> vertices = [];
  final List<Face3> faces = [];

  int addVertex(Vec3 point) {
    vertices.add(point);
    return vertices.length - 1;
  }

  void triangle(
    Vec3 a,
    Vec3 b,
    Vec3 c,
    Color color, {
    bool doubleSided = false,
    double emissive = 0,
  }) {
    final ia = addVertex(a);
    final ib = addVertex(b);
    final ic = addVertex(c);
    faces.add(
        Face3(ia, ib, ic, color, doubleSided: doubleSided, emissive: emissive));
  }

  void quad(
    Vec3 a,
    Vec3 b,
    Vec3 c,
    Vec3 d,
    Color color, {
    bool doubleSided = false,
    Vec3? outward,
    double emissive = 0,
  }) {
    var p1 = a;
    var p2 = b;
    var p3 = c;
    var p4 = d;
    if (outward != null) {
      final normal = (b - a).cross(c - a);
      final faceCenter = (a + b + c + d) * 0.25;
      if (normal.dot(faceCenter - outward) < 0) {
        p1 = d;
        p2 = c;
        p3 = b;
        p4 = a;
      }
    }
    triangle(p1, p2, p3, color, doubleSided: doubleSided, emissive: emissive);
    triangle(p1, p3, p4, color, doubleSided: doubleSided, emissive: emissive);
  }

  void box({
    required Vec3 center,
    required Vec3 size,
    required Color color,
    Vec3 rotation = Vec3.zero,
    Color? topColor,
    bool bottom = true,
    bool doubleSided = false,
    double emissive = 0,
  }) {
    final hx = size.x / 2;
    final hy = size.y / 2;
    final hz = size.z / 2;
    Vec3 point(double x, double y, double z) {
      var p = Vec3(x * hx, y * hy, z * hz);
      if (rotation.x != 0) p = p.rotateX(rotation.x);
      if (rotation.y != 0) p = p.rotateY(rotation.y);
      if (rotation.z != 0) p = p.rotateZ(rotation.z);
      return p + center;
    }

    final p000 = point(-1, -1, -1);
    final p001 = point(-1, -1, 1);
    final p010 = point(-1, 1, -1);
    final p011 = point(-1, 1, 1);
    final p100 = point(1, -1, -1);
    final p101 = point(1, -1, 1);
    final p110 = point(1, 1, -1);
    final p111 = point(1, 1, 1);

    final up = topColor ?? color;
    quad(p011, p111, p110, p010, up,
        outward: center, doubleSided: doubleSided, emissive: emissive);
    if (bottom) {
      quad(p000, p100, p101, p001, color,
          outward: center, doubleSided: doubleSided, emissive: emissive);
    }
    quad(p001, p101, p111, p011, color,
        outward: center, doubleSided: doubleSided, emissive: emissive);
    quad(p000, p010, p110, p100, color,
        outward: center, doubleSided: doubleSided, emissive: emissive);
    quad(p001, p011, p010, p000, color,
        outward: center, doubleSided: doubleSided, emissive: emissive);
    quad(p101, p100, p110, p111, color,
        outward: center, doubleSided: doubleSided, emissive: emissive);
  }

  void cylinder({
    required Vec3 base,
    required double radius,
    required double height,
    required Color color,
    int segments = 12,
    Color? topColor,
    double radiusTop = -1,
    bool capTop = true,
    bool capBottom = true,
    bool doubleSided = false,
    double emissive = 0,
  }) {
    final rTop = radiusTop < 0 ? radius : radiusTop;
    final axisCenter = base + Vec3(0, height / 2, 0);
    final bottom = <Vec3>[];
    final top = <Vec3>[];
    for (var i = 0; i < segments; i++) {
      final angle = (i / segments) * math.pi * 2;
      final cos = math.cos(angle);
      final sin = math.sin(angle);
      bottom.add(base + Vec3(cos * radius, 0, sin * radius));
      top.add(base + Vec3(cos * rTop, height, sin * rTop));
    }
    for (var i = 0; i < segments; i++) {
      final next = (i + 1) % segments;
      quad(
        bottom[i],
        bottom[next],
        top[next],
        top[i],
        color,
        outward: axisCenter,
        doubleSided: doubleSided,
        emissive: emissive,
      );
    }
    if (capTop) {
      final centerTop = base + Vec3(0, height, 0);
      for (var i = 0; i < segments; i++) {
        final next = (i + 1) % segments;
        triangle(centerTop, top[next], top[i], topColor ?? color,
            doubleSided: doubleSided, emissive: emissive);
      }
    }
    if (capBottom) {
      for (var i = 0; i < segments; i++) {
        final next = (i + 1) % segments;
        triangle(base, bottom[i], bottom[next], color,
            doubleSided: doubleSided, emissive: emissive);
      }
    }
  }

  void dome({
    required Vec3 center,
    required double radius,
    required Color color,
    int rings = 6,
    int segments = 14,
    double squashY = 1,
    bool doubleSided = false,
  }) {
    final rows = <List<Vec3>>[];
    for (var r = 0; r <= rings; r++) {
      final phi = (r / rings) * (math.pi / 2);
      final y = math.sin(phi) * radius * squashY;
      final ringRadius = math.cos(phi) * radius;
      final row = <Vec3>[];
      for (var s = 0; s < segments; s++) {
        final theta = (s / segments) * math.pi * 2;
        row.add(center +
            Vec3(
                math.cos(theta) * ringRadius, y, math.sin(theta) * ringRadius));
      }
      rows.add(row);
    }
    for (var r = 0; r < rings; r++) {
      for (var s = 0; s < segments; s++) {
        final next = (s + 1) % segments;
        quad(
          rows[r][s],
          rows[r][next],
          rows[r + 1][next],
          rows[r + 1][s],
          color,
          outward: center,
          doubleSided: doubleSided,
        );
      }
    }
  }

  void sphere({
    required Vec3 center,
    required double radius,
    required Color color,
    int rings = 6,
    int segments = 12,
    Vec3 scale = const Vec3(1, 1, 1),
    bool doubleSided = false,
    double emissive = 0,
  }) {
    final grid = <List<Vec3>>[];
    for (var r = 0; r <= rings; r++) {
      final phi = (r / rings) * math.pi;
      final y = math.cos(phi) * radius * scale.y;
      final ringRadius = math.sin(phi) * radius;
      final row = <Vec3>[];
      for (var s = 0; s < segments; s++) {
        final theta = (s / segments) * math.pi * 2;
        row.add(center +
            Vec3(math.cos(theta) * ringRadius * scale.x, y,
                math.sin(theta) * ringRadius * scale.z));
      }
      grid.add(row);
    }
    for (var r = 0; r < rings; r++) {
      for (var s = 0; s < segments; s++) {
        final next = (s + 1) % segments;
        quad(
          grid[r][s],
          grid[r][next],
          grid[r + 1][next],
          grid[r + 1][s],
          color,
          outward: center,
          doubleSided: doubleSided,
          emissive: emissive,
        );
      }
    }
  }

  /// Rectangular beam from a to b. Used for pipes, struts and wires.
  void beam({
    required Vec3 a,
    required Vec3 b,
    required double thickness,
    required Color color,
    bool doubleSided = false,
    double emissive = 0,
  }) {
    final direction = (b - a).normalized;
    if (direction.length < 0.001) return;
    final helper =
        direction.y.abs() > 0.92 ? const Vec3(1, 0, 0) : const Vec3(0, 1, 0);
    final side = direction.cross(helper).normalized * (thickness / 2);
    final up = side.cross(direction).normalized * (thickness / 2);
    final corners = [
      a - side - up,
      a + side - up,
      a + side + up,
      a - side + up,
    ];
    final far = [
      b - side - up,
      b + side - up,
      b + side + up,
      b - side + up,
    ];
    final center = (a + b) * 0.5;
    for (var i = 0; i < 4; i++) {
      final next = (i + 1) % 4;
      quad(corners[i], corners[next], far[next], far[i], color,
          outward: center, doubleSided: doubleSided, emissive: emissive);
    }
    quad(corners[0], corners[3], corners[2], corners[1], color,
        outward: a, doubleSided: doubleSided, emissive: emissive);
    quad(far[0], far[1], far[2], far[3], color,
        outward: b, doubleSided: doubleSided, emissive: emissive);
  }

  /// A flat, soft looking ring (in the XZ plane) for beacons and shields.
  void ring({
    required Vec3 center,
    required double outerRadius,
    required double innerRadius,
    required Color color,
    int segments = 32,
    bool vertical = false,
    bool doubleSided = true,
    double emissive = 0.7,
  }) {
    for (var i = 0; i < segments; i++) {
      final a0 = (i / segments) * math.pi * 2;
      final a1 = ((i + 1) / segments) * math.pi * 2;
      Vec3 point(double angle, double radius) {
        final x = math.cos(angle) * radius;
        final y = math.sin(angle) * radius;
        if (vertical) return center + Vec3(x, y, 0);
        return center + Vec3(x, 0, y);
      }

      quad(
        point(a0, innerRadius),
        point(a0, outerRadius),
        point(a1, outerRadius),
        point(a1, innerRadius),
        color,
        doubleSided: doubleSided,
        emissive: emissive,
      );
    }
  }

  /// Stylised 3D leaf made from two curved diamonds.
  void leaf({
    required Vec3 base,
    required Vec3 direction,
    required double length,
    required double width,
    required Color color,
    double bend = 0.25,
    Color? tipColor,
  }) {
    final forward = direction.normalized;
    final side = forward.cross(const Vec3(0, 1, 0));
    final lateral =
        (side.length < 0.001 ? const Vec3(1, 0, 0) : side.normalized) * width;
    final mid = base +
        forward * (length * 0.48) +
        Vec3(0, math.sin(bend) * length * 0.12, 0);
    final tip = base + forward * length + Vec3(0, bend * length * 0.32, 0);
    final baseLeft = base - lateral;
    final baseRight = base + lateral;
    final midLeft = mid - lateral * 0.9;
    final midRight = mid + lateral * 0.9;
    final upper = tip + Vec3(0, 0.02, 0);
    final lower = base - Vec3(0, 0.035, 0);
    final c = tipColor ?? color;
    triangle(baseLeft, midLeft, upper, color, doubleSided: true);
    triangle(midLeft, midRight, upper, color, doubleSided: true);
    triangle(baseRight, midRight, upper, c, doubleSided: true);
    triangle(baseLeft, upper, lower, color, doubleSided: true);
    triangle(baseRight, lower, upper, color, doubleSided: true);
    triangle(baseLeft, lower, base, color, doubleSided: true);
    triangle(base, lower, baseRight, color, doubleSided: true);
  }

  Mesh3 copy() {
    final copy = Mesh3();
    copy.vertices.addAll(vertices);
    copy.faces.addAll(faces);
    return copy;
  }

  Mesh3 transformed(
      {Vec3 offset = Vec3.zero,
      Vec3 rotation = Vec3.zero,
      Vec3 scale = const Vec3(1, 1, 1)}) {
    final result = Mesh3();
    final cosX = math.cos(rotation.x);
    final sinX = math.sin(rotation.x);
    final cosY = math.cos(rotation.y);
    final sinY = math.sin(rotation.y);
    final cosZ = math.cos(rotation.z);
    final sinZ = math.sin(rotation.z);
    for (final vertex in vertices) {
      var x = vertex.x * scale.x;
      var y = vertex.y * scale.y;
      var z = vertex.z * scale.z;
      final y1 = y * cosX - z * sinX;
      final z1 = y * sinX + z * cosX;
      y = y1;
      z = z1;
      final x1 = x * cosY + z * sinY;
      final z2 = -x * sinY + z * cosY;
      x = x1;
      z = z2;
      final x2 = x * cosZ - y * sinZ;
      final y2 = x * sinZ + y * cosZ;
      result.vertices.add(Vec3(x2 + offset.x, y2 + offset.y, z + offset.z));
    }
    result.faces.addAll(faces);
    return result;
  }
}

class RenderObject3D {
  const RenderObject3D({
    required this.mesh,
    this.position = Vec3.zero,
    this.rotation = Vec3.zero,
    this.scale = const Vec3(1, 1, 1),
    this.opacity = 1,
    this.castShadow = true,
    this.shadowRadius = 1.4,
  });

  final Mesh3 mesh;
  final Vec3 position;
  final Vec3 rotation;
  final Vec3 scale;
  final double opacity;
  final bool castShadow;
  final double shadowRadius;
}

import 'dart:math' as math;
import 'dart:ui';

class Vec3 {
  const Vec3(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;

  static const zero = Vec3(0, 0, 0);

  Vec3 operator +(Vec3 other) => Vec3(x + other.x, y + other.y, z + other.z);
  Vec3 operator -(Vec3 other) => Vec3(x - other.x, y - other.y, z - other.z);
  Vec3 operator *(double scalar) => Vec3(x * scalar, y * scalar, z * scalar);
  Vec3 operator /(double scalar) => Vec3(x / scalar, y / scalar, z / scalar);

  double dot(Vec3 other) => x * other.x + y * other.y + z * other.z;

  Vec3 cross(Vec3 other) => Vec3(
        y * other.z - z * other.y,
        z * other.x - x * other.z,
        x * other.y - y * other.x,
      );

  double get length => math.sqrt(x * x + y * y + z * z);

  Vec3 get normalized {
    final len = length;
    if (len < 0.000001) return zero;
    return Vec3(x / len, y / len, z / len);
  }

  Vec3 lerp(Vec3 other, double t) => Vec3(
        x + (other.x - x) * t,
        y + (other.y - y) * t,
        z + (other.z - z) * t,
      );

  double distanceTo(Vec3 other) => (this - other).length;

  Vec3 rotateX(double angle) {
    final cos = math.cos(angle);
    final sin = math.sin(angle);
    return Vec3(x, y * cos - z * sin, y * sin + z * cos);
  }

  Vec3 rotateY(double angle) {
    final cos = math.cos(angle);
    final sin = math.sin(angle);
    return Vec3(x * cos + z * sin, y, -x * sin + z * cos);
  }

  Vec3 rotateZ(double angle) {
    final cos = math.cos(angle);
    final sin = math.sin(angle);
    return Vec3(x * cos - y * sin, x * sin + y * cos, z);
  }

  @override
  String toString() =>
      'Vec3(${x.toStringAsFixed(2)}, ${y.toStringAsFixed(2)}, ${z.toStringAsFixed(2)})';
}

class ProjectedPoint {
  const ProjectedPoint(this.offset, this.depth, this.scale);

  final Offset offset;
  final double depth;
  final double scale;
}

class OrbitCamera {
  OrbitCamera({
    this.yaw = 0.58,
    this.pitch = 0.36,
    this.distance = 16,
    this.target = const Vec3(0, 1.7, 0),
    this.fovY = 0.72,
    this.minDistance = 7,
    this.maxDistance = 30,
    this.minPitch = 0.06,
    this.maxPitch = 1.25,
  });

  double yaw;
  double pitch;
  double distance;
  Vec3 target;
  double fovY;
  double minDistance;
  double maxDistance;
  double minPitch;
  double maxPitch;

  Vec3 get position {
    final horizontal = math.cos(pitch) * distance;
    return Vec3(
      target.x + horizontal * math.sin(yaw),
      target.y + math.sin(pitch) * distance,
      target.z + horizontal * math.cos(yaw),
    );
  }

  void orbitBy(double deltaX, double deltaY) {
    yaw -= deltaX * 0.006;
    pitch = (pitch + deltaY * 0.005).clamp(minPitch, maxPitch);
  }

  void zoomBy(double factor) {
    distance = (distance * factor).clamp(minDistance, maxDistance);
  }

  void reset({double? yawValue, double? pitchValue, double? distanceValue}) {
    yaw = yawValue ?? 0.58;
    pitch = pitchValue ?? 0.36;
    distance = distanceValue ?? 16;
  }

  ProjectedPoint? project(Vec3 world, Size size) {
    final eye = position;
    final forward = (target - eye).normalized;
    final worldUp = const Vec3(0, 1, 0);
    var right = forward.cross(worldUp).normalized;
    if (right.length < 0.001) right = const Vec3(1, 0, 0);
    final up = right.cross(forward).normalized;
    final relative = world - eye;
    final depth = relative.dot(forward);
    if (depth <= 0.15) return null;
    final focal = (size.height * 0.5) / math.tan(fovY * 0.5);
    final x = size.width * 0.5 + relative.dot(right) * focal / depth;
    final y = size.height * 0.5 - relative.dot(up) * focal / depth;
    return ProjectedPoint(Offset(x, y), depth, focal / depth);
  }
}

Color mixColor(Color a, Color b, double t) {
  final clamped = t.clamp(0.0, 1.0);
  return Color.lerp(a, b, clamped) ?? a;
}

Color scaleColor(Color color, double factor) {
  return Color.fromARGB(
    (color.a * 255).round(),
    ((color.r * 255) * factor).round().clamp(0, 255),
    ((color.g * 255) * factor).round().clamp(0, 255),
    ((color.b * 255) * factor).round().clamp(0, 255),
  );
}

Color withAlpha(Color color, double alpha) =>
    color.withValues(alpha: alpha.clamp(0.0, 1.0));

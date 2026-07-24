import 'dart:math' as math;

final class Vec2 {
  final double x;
  final double y;

  const Vec2(this.x, this.y);

  static const zero = Vec2(0, 0);

  Vec2 operator +(Vec2 other) => Vec2(x + other.x, y + other.y);
  Vec2 operator -(Vec2 other) => Vec2(x - other.x, y - other.y);
  Vec2 operator *(double scale) => Vec2(x * scale, y * scale);

  double get lengthSquared => (x * x) + (y * y);
  double get length => math.sqrt(lengthSquared);

  Vec2 normalized() {
    final magnitude = length;
    return magnitude <= 0.000001 ? zero : Vec2(x / magnitude, y / magnitude);
  }

  double distanceTo(Vec2 other) => (this - other).length;

  Map<String, Object> toJson() => {'x': x, 'y': y};

  @override
  bool operator ==(Object other) {
    return other is Vec2 && other.x == x && other.y == y;
  }

  @override
  int get hashCode => Object.hash(x, y);
}

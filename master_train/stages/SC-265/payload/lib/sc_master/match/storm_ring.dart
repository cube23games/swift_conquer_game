final class StormRing {
  final double initialRadius;
  final double minimumRadius;
  final double shrinkPerTick;

  const StormRing({
    required this.initialRadius,
    required this.minimumRadius,
    required this.shrinkPerTick,
  });

  double radiusAt(int activeTicks) {
    final radius = initialRadius - (activeTicks * shrinkPerTick);
    return radius.clamp(minimumRadius, initialRadius).toDouble();
  }
}

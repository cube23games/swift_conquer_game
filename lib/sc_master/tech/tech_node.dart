final class TechNode {
  final String id;
  final Set<String> prerequisites;
  final Set<String> unlocks;

  const TechNode({
    required this.id,
    this.prerequisites = const {},
    this.unlocks = const {},
  });
}

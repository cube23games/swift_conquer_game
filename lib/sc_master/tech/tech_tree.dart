import 'tech_node.dart';

final class TechTree {
  final Map<String, TechNode> nodes;

  TechTree(Iterable<TechNode> nodes)
      : nodes = {for (final node in nodes) node.id: node};

  bool canResearch(String id, Set<String> researched) {
    final node = nodes[id];
    if (node == null || researched.contains(id)) return false;
    return node.prerequisites.every(researched.contains);
  }

  Set<String> available(Set<String> researched) {
    return nodes.keys.where((id) => canResearch(id, researched)).toSet();
  }
}

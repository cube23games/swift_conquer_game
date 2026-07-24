final class TechAccess {
  final Map<int, Set<String>> _stolen = {};

  void grantStolen(int teamId, Iterable<String> techIds) {
    _stolen.putIfAbsent(teamId, () => {}).addAll(techIds);
  }

  Set<String> stolenFor(int teamId) {
    return Set.unmodifiable(_stolen[teamId] ?? const {});
  }

  int removeBySellingSource({
    required int teamId,
    required int sourceFaceValue,
  }) {
    _stolen.remove(teamId);
    return (sourceFaceValue * 0.10).floor();
  }
}

import '../world/world_state.dart';

final class VictoryResult {
  final int? winnerTeamId;
  final bool draw;

  const VictoryResult({this.winnerTeamId, this.draw = false});

  bool get finished => winnerTeamId != null || draw;
}

final class VictoryCondition {
  const VictoryCondition();

  VictoryResult evaluate(WorldState world) {
    final active = <int>{};
    for (final unit in world.units.values) {
      if (unit.alive) active.add(unit.teamId);
    }
    for (final building in world.buildings.values) {
      if (building.alive) active.add(building.teamId);
    }
    if (active.isEmpty) return const VictoryResult(draw: true);
    if (active.length == 1) {
      return VictoryResult(winnerTeamId: active.single);
    }
    return const VictoryResult();
  }
}

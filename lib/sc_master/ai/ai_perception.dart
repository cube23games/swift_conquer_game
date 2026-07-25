import '../core/id/entity_id.dart';
import '../world/world_state.dart';

final class AiPerception {
  final List<EntityId> friendlyUnits;
  final List<EntityId> enemyUnits;
  final List<EntityId> friendlyBuildings;
  final List<EntityId> enemyBuildings;

  const AiPerception({
    required this.friendlyUnits,
    required this.enemyUnits,
    required this.friendlyBuildings,
    required this.enemyBuildings,
  });

  factory AiPerception.fromWorld(WorldState world, int teamId) {
    List<EntityId> ids(Iterable<EntityId> values) => values.toList()..sort();
    return AiPerception(
      friendlyUnits: ids(world.units.values
          .where((unit) => unit.alive && unit.teamId == teamId)
          .map((unit) => unit.id)),
      enemyUnits: ids(world.units.values
          .where((unit) => unit.alive && unit.teamId != teamId)
          .map((unit) => unit.id)),
      friendlyBuildings: ids(world.buildings.values
          .where((building) => building.alive && building.teamId == teamId)
          .map((building) => building.id)),
      enemyBuildings: ids(world.buildings.values
          .where((building) => building.alive && building.teamId != teamId)
          .map((building) => building.id)),
    );
  }
}

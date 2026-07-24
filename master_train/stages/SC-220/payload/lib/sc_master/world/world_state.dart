import '../core/entities/entity_store.dart';
import '../core/id/entity_id.dart';
import '../core/math/vec2.dart';
import 'building_state.dart';
import 'team_state.dart';
import 'unit_state.dart';

final class WorldState {
  final EntityStore entities = EntityStore();
  final Map<EntityId, UnitState> units = {};
  final Map<EntityId, BuildingState> buildings = {};
  final Map<int, TeamState> teams = {};
  int tick = 0;

  TeamState team(int id) {
    return teams.putIfAbsent(id, () => TeamState(id: id));
  }

  EntityId spawnUnit({
    required int teamId,
    required String archetype,
    required Vec2 position,
    int health = 100,
    UnitDomain domain = UnitDomain.land,
  }) {
    final id = entities.create(teamId: teamId, kind: 'unit');
    units[id] = UnitState(
      id: id,
      teamId: teamId,
      archetype: archetype,
      position: position,
      health: health,
      maxHealth: health,
      domain: domain,
    );
    team(teamId);
    return id;
  }

  EntityId spawnBuilding({
    required int teamId,
    required String archetype,
    required Vec2 position,
    int health = 250,
  }) {
    final id = entities.create(teamId: teamId, kind: 'building');
    buildings[id] = BuildingState(
      id: id,
      teamId: teamId,
      archetype: archetype,
      position: position,
      health: health,
      maxHealth: health,
    );
    team(teamId);
    return id;
  }

  bool destroy(EntityId id) {
    final changed = entities.destroy(id);
    final unit = units[id];
    final building = buildings[id];
    if (unit != null) unit.alive = false;
    if (building != null) building.alive = false;
    return changed;
  }

  Map<String, Object?> snapshot() => {
        'tick': tick,
        'units': (units.values
              .where((unit) => unit.alive)
              .map((unit) => unit.id.value)
              .toList()
            ..sort()),
        'buildings': (buildings.values
              .where((building) => building.alive)
              .map((building) => building.id.value)
              .toList()
            ..sort()),
        'teams': (teams.keys.toList()..sort()),
      };
}

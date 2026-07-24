import '../core/id/entity_id.dart';
import '../world/world_state.dart';

enum RepairMode { none, manual, engineers }

final class RepairService {
  const RepairService();

  int repairBuilding({
    required WorldState world,
    required EntityId buildingId,
    required Iterable<EntityId> engineerIds,
    required RepairMode mode,
    bool lowPower = false,
    int pointsPerEngineer = 3,
    int manualPoints = 5,
  }) {
    final building = world.buildings[buildingId];
    if (building == null || !building.alive) return 0;
    if (mode == RepairMode.none) return 0;

    var points = manualPoints;
    if (mode == RepairMode.engineers) {
      final valid = engineerIds.where((id) {
        final unit = world.units[id];
        return unit != null &&
            unit.alive &&
            unit.teamId == building.teamId &&
            unit.archetype == 'engineer';
      }).take(3).length;
      points = valid * pointsPerEngineer;
      if (lowPower) points = (points * 0.5).floor();
    }

    final before = building.health;
    building.health = (building.health + points)
        .clamp(0, building.maxHealth)
        .toInt();
    return building.health - before;
  }
}

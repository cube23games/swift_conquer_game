import '../core/id/entity_id.dart';
import '../core/math/vec2.dart';
import '../world/world_state.dart';

final class TargetSelector {
  const TargetSelector();

  EntityId? nearestEnemy({
    required WorldState world,
    required int teamId,
    required Vec2 origin,
    required double range,
  }) {
    final candidates = <(EntityId, double)>[];
    for (final unit in world.units.values) {
      if (!unit.alive || unit.teamId == teamId) continue;
      final distance = unit.position.distanceTo(origin);
      if (distance <= range) candidates.add((unit.id, distance));
    }
    for (final building in world.buildings.values) {
      if (!building.alive || building.teamId == teamId) continue;
      final distance = building.position.distanceTo(origin);
      if (distance <= range) candidates.add((building.id, distance));
    }
    candidates.sort((a, b) {
      final distance = a.$2.compareTo(b.$2);
      return distance != 0 ? distance : a.$1.compareTo(b.$1);
    });
    return candidates.isEmpty ? null : candidates.first.$1;
  }
}

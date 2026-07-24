import '../core/id/entity_id.dart';
import '../world/world_state.dart';

enum InfiltrationMode { capture, sabotage }

final class InfiltrationResult {
  final bool completed;
  final int progress;

  const InfiltrationResult(this.completed, this.progress);
}

final class InfiltrationService {
  final Map<EntityId, int> _progress = {};

  InfiltrationResult apply({
    required WorldState world,
    required EntityId engineerId,
    required EntityId buildingId,
    required InfiltrationMode mode,
    int amount = 25,
  }) {
    final engineer = world.units[engineerId];
    final building = world.buildings[buildingId];
    if (engineer == null ||
        building == null ||
        !engineer.alive ||
        !building.alive ||
        engineer.archetype != 'engineer' ||
        engineer.teamId == building.teamId) {
      return const InfiltrationResult(false, 0);
    }

    final next = ((_progress[buildingId] ?? 0) + amount)
        .clamp(0, 100)
        .toInt();
    _progress[buildingId] = next;
    if (next < 100) return InfiltrationResult(false, next);

    if (mode == InfiltrationMode.sabotage) {
      building.powered = false;
    }
    return InfiltrationResult(true, next);
  }
}

import '../core/math/vec2.dart';
import '../world/world_state.dart';
import 'move_command.dart';

final class MoveOrderService {
  const MoveOrderService();

  int apply(WorldState world, MoveCommand command) {
    var changed = 0;
    for (final id in command.units) {
      final unit = world.units[id];
      if (unit == null || !unit.alive || unit.teamId != command.playerId) {
        continue;
      }
      unit.moveTarget = Vec2(
        command.destination.x,
        command.destination.y,
      );
      changed += 1;
    }
    return changed;
  }
}

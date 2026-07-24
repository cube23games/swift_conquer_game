import '../core/math/vec2.dart';
import '../orders/move_command.dart';
import '../orders/move_order_service.dart';
import '../world/world_state.dart';
import 'formation_planner.dart';

final class ControlSmoke {
  const ControlSmoke();

  bool run() {
    final world = WorldState();
    final a = world.spawnUnit(
      teamId: 1, archetype: 'tank', position: Vec2.zero);
    final b = world.spawnUnit(
      teamId: 1, archetype: 'tank', position: const Vec2(10, 0));
    final targets = const FormationPlanner().plan(
      units: [a, b], destination: const Vec2(100, 100));
    var applied = 0;
    for (final entry in targets.entries) {
      applied += const MoveOrderService().apply(world, MoveCommand(
        tick: 1,
        playerId: 1,
        units: [entry.key],
        destination: entry.value,
      ));
    }
    return applied == 2 &&
        world.units[a]!.moveTarget != world.units[b]!.moveTarget;
  }
}

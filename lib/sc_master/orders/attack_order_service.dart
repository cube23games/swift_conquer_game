import '../world/world_state.dart';
import 'attack_command.dart';

final class AttackOrderService {
  const AttackOrderService();

  int apply(WorldState world, AttackCommand command) {
    final targetTeam = world.units[command.target]?.teamId ??
        world.buildings[command.target]?.teamId;
    if (targetTeam == null || targetTeam == command.playerId) return 0;

    var changed = 0;
    for (final id in command.attackers) {
      final unit = world.units[id];
      if (unit == null || !unit.alive || unit.teamId != command.playerId) {
        continue;
      }
      unit.attackTarget = command.target;
      changed += 1;
    }
    return changed;
  }
}

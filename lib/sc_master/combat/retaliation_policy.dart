import '../core/id/entity_id.dart';
import '../world/world_state.dart';

final class RetaliationPolicy {
  const RetaliationPolicy();

  bool retaliate({
    required WorldState world,
    required EntityId defenderId,
    required EntityId attackerId,
  }) {
    final defender = world.units[defenderId];
    final attackerTeam = world.units[attackerId]?.teamId ??
        world.buildings[attackerId]?.teamId;
    if (defender == null ||
        !defender.alive ||
        attackerTeam == null ||
        attackerTeam == defender.teamId) {
      return false;
    }
    defender.attackTarget ??= attackerId;
    return true;
  }
}

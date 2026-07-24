import '../core/math/vec2.dart';
import '../engineer/repair_service.dart';
import '../world/world_state.dart';
import 'combat_resolver.dart';
import 'damage_packet.dart';

final class CombatSmoke {
  const CombatSmoke();

  bool run() {
    final world = WorldState();
    final target = world.spawnBuilding(
      teamId: 1,
      archetype: 'hq',
      position: Vec2.zero,
      health: 100,
    );
    final engineer = world.spawnUnit(
      teamId: 1,
      archetype: 'engineer',
      position: const Vec2(1, 0),
    );
    const CombatResolver().applyDamage(
      world: world,
      target: target,
      packet: const DamagePacket(
        amount: 30,
        type: DamageType.explosive,
      ),
    );
    final repaired = const RepairService().repairBuilding(
      world: world,
      buildingId: target,
      engineerIds: [engineer],
      mode: RepairMode.engineers,
      pointsPerEngineer: 10,
    );
    return repaired == 10 && world.buildings[target]!.health == 80;
  }
}

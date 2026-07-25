import '../combat/combat_resolver.dart';
import '../combat/damage_packet.dart';
import '../construction/building_lifecycle.dart';
import '../core/id/entity_id.dart';
import '../core/math/vec2.dart';
import '../economy/harvester_state.dart';
import '../economy/refinery_service.dart';
import '../economy/wallet.dart';
import '../world/world_state.dart';

final class ScMasterDemoController {
  final WorldState world = WorldState();
  final Wallet wallet = Wallet();
  late final EntityId mobileHq;
  EntityId? hq;
  EntityId? enemy;
  String message = 'Move the Mobile HQ Center, then deploy.';

  ScMasterDemoController() {
    mobileHq = world.spawnUnit(
      teamId: 1,
      archetype: 'mobile_hq_center',
      position: const Vec2(100, 100),
    );
  }

  void moveMobileHq() {
    final unit = world.units[mobileHq];
    if (unit == null || !unit.alive) return;
    unit.position = const Vec2(220, 160);
    message = 'Mobile HQ Center moved.';
  }

  void deployHq() {
    hq = const BuildingLifecycle().deployMobileHq(world, mobileHq);
    message = hq == null ? 'Deployment unavailable.' : 'HQ deployed.';
  }

  void harvestOre() {
    final harvester = HarvesterState(
      unitId: world.spawnUnit(
        teamId: 1,
        archetype: 'harvester',
        position: const Vec2(260, 180),
      ),
    )..collect(500);
    final earned = const RefineryService().unload(
      harvester: harvester,
      wallet: wallet,
    );
    message = 'Ore delivered: +$earned credits.';
  }

  void spawnEnemy() {
    enemy ??= world.spawnUnit(
      teamId: 2,
      archetype: 'tank',
      position: const Vec2(500, 200),
      health: 40,
    );
    message = 'Enemy tank detected.';
  }

  void attackEnemy() {
    spawnEnemy();
    const CombatResolver().applyDamage(
      world: world,
      target: enemy!,
      packet: const DamagePacket(
        amount: 20,
        type: DamageType.kinetic,
      ),
    );
    final target = world.units[enemy!];
    message = target == null || !target.alive
        ? 'Enemy destroyed.'
        : 'Enemy health: ${target.health}.';
  }

  int get friendlyAssets {
    return world.units.values.where((unit) => unit.alive && unit.teamId == 1).length +
        world.buildings.values.where(
          (building) => building.alive && building.teamId == 1).length;
  }
}

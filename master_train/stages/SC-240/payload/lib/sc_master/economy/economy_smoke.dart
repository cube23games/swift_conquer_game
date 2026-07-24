import '../construction/building_lifecycle.dart';
import '../core/math/vec2.dart';
import '../economy/harvester_state.dart';
import '../economy/refinery_service.dart';
import '../economy/wallet.dart';
import '../world/world_state.dart';

final class EconomySmoke {
  const EconomySmoke();

  bool run() {
    final world = WorldState();
    final mobile = world.spawnUnit(
      teamId: 1,
      archetype: 'mobile_hq_center',
      position: Vec2.zero,
    );
    final hq = const BuildingLifecycle().deployMobileHq(world, mobile);
    final harvester = HarvesterState(unitId: world.spawnUnit(
      teamId: 1,
      archetype: 'harvester',
      position: const Vec2(10, 0),
    ))..collect(200);
    final wallet = Wallet(balance: 15000);
    final credits = const RefineryService().unload(
      harvester: harvester,
      wallet: wallet,
    );
    return hq != null && credits == 200 && wallet.balance == 15200;
  }
}

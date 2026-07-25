import '../core/id/entity_id.dart';
import '../world/world_state.dart';

final class BuildingLifecycle {
  const BuildingLifecycle();

  EntityId? deployMobileHq(WorldState world, EntityId mobileId) {
    final mobile = world.units[mobileId];
    if (mobile == null ||
        !mobile.alive ||
        mobile.archetype != 'mobile_hq_center') {
      return null;
    }
    final hq = world.spawnBuilding(
      teamId: mobile.teamId,
      archetype: 'hq',
      position: mobile.position,
      health: 300,
    );
    world.destroy(mobileId);
    return hq;
  }
}

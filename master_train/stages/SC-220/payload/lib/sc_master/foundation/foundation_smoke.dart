import '../core/math/vec2.dart';
import '../core/replay/state_hasher.dart';
import '../world/world_state.dart';

final class FoundationSmoke {
  const FoundationSmoke();

  int run() {
    final world = WorldState();
    world.spawnUnit(
      teamId: 1,
      archetype: 'mobile_hq_center',
      position: const Vec2(100, 100),
    );
    world.spawnBuilding(
      teamId: 2,
      archetype: 'hq',
      position: const Vec2(900, 500),
    );
    return const StateHasher().hashJson(world.snapshot());
  }
}

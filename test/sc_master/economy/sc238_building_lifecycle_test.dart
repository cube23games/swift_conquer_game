import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/construction/building_lifecycle.dart';
import 'package:swift_conquer_game/sc_master/core/math/vec2.dart';
import 'package:swift_conquer_game/sc_master/world/world_state.dart';

void main() {
  test('SC-238 mobile HQ disappears into deployed HQ', () {
    final world = WorldState();
    final mobile = world.spawnUnit(
      teamId: 1, archetype: 'mobile_hq_center', position: Vec2.zero);
    final hq = const BuildingLifecycle().deployMobileHq(world, mobile);
    expect(hq, isNotNull);
    expect(world.units[mobile]!.alive, isFalse);
    expect(world.buildings[hq]!.archetype, 'hq');
  });
}

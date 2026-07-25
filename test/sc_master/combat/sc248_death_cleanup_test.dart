import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/combat/death_cleanup.dart';
import 'package:swift_conquer_game/sc_master/core/math/vec2.dart';
import 'package:swift_conquer_game/sc_master/world/world_state.dart';

void main() {
  test('SC-248 dead units become stable wreck records', () {
    final world = WorldState();
    final unit = world.spawnUnit(
      teamId: 1, archetype: 'tank', position: Vec2.zero);
    world.destroy(unit);
    final cleanup = DeathCleanup()..run(world);
    expect(world.units.containsKey(unit), isFalse);
    expect(cleanup.wrecks.single.sourceId, unit);
  });
}

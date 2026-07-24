import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/combat/target_selector.dart';
import 'package:swift_conquer_game/sc_master/core/math/vec2.dart';
import 'package:swift_conquer_game/sc_master/world/world_state.dart';

void main() {
  test('SC-228 equal-distance targets use entity id tie break', () {
    final world = WorldState();
    final first = world.spawnUnit(
      teamId: 2, archetype: 'tank', position: const Vec2(10, 0));
    world.spawnUnit(
      teamId: 2, archetype: 'tank', position: const Vec2(-10, 0));
    expect(const TargetSelector().nearestEnemy(
      world: world, teamId: 1, origin: Vec2.zero, range: 20), first);
  });
}

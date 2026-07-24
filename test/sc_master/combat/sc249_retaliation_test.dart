import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/combat/retaliation_policy.dart';
import 'package:swift_conquer_game/sc_master/core/math/vec2.dart';
import 'package:swift_conquer_game/sc_master/world/world_state.dart';

void main() {
  test('SC-249 enemy units auto-fight back', () {
    final world = WorldState();
    final defender = world.spawnUnit(
      teamId: 1, archetype: 'tank', position: Vec2.zero);
    final attacker = world.spawnUnit(
      teamId: 2, archetype: 'tank', position: Vec2.zero);
    expect(const RetaliationPolicy().retaliate(
      world: world, defenderId: defender, attackerId: attacker), isTrue);
    expect(world.units[defender]!.attackTarget, attacker);
  });
}

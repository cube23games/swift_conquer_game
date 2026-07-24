import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/construction/build_rule.dart';
import 'package:swift_conquer_game/sc_master/core/math/vec2.dart';
import 'package:swift_conquer_game/sc_master/world/world_state.dart';

void main() {
  test('SC-237 owned buildings anchor build radius', () {
    final world = WorldState()
      ..spawnBuilding(teamId: 1, archetype: 'hq', position: Vec2.zero);
    expect(const BuildRule(radius: 30).canBuild(
      world: world, teamId: 1, position: const Vec2(20, 0)), isTrue);
    expect(const BuildRule(radius: 30).canBuild(
      world: world, teamId: 2, position: const Vec2(20, 0)), isFalse);
  });
}

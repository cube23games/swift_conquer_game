import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/ai/ai_perception.dart';
import 'package:swift_conquer_game/sc_master/core/math/vec2.dart';
import 'package:swift_conquer_game/sc_master/world/world_state.dart';

void main() {
  test('SC-261 AI perception sorts entity ids', () {
    final world = WorldState();
    world.spawnUnit(teamId: 2, archetype: 'tank', position: Vec2.zero);
    world.spawnUnit(teamId: 1, archetype: 'tank', position: Vec2.zero);
    final perception = AiPerception.fromWorld(world, 1);
    expect(perception.friendlyUnits, hasLength(1));
    expect(perception.enemyUnits, hasLength(1));
  });
}

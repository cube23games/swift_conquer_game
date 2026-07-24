import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/core/math/vec2.dart';
import 'package:swift_conquer_game/sc_master/match/victory_condition.dart';
import 'package:swift_conquer_game/sc_master/world/world_state.dart';

void main() {
  test('SC-266 one surviving team wins', () {
    final world = WorldState()
      ..spawnBuilding(teamId: 1, archetype: 'hq', position: Vec2.zero);
    expect(const VictoryCondition().evaluate(world).winnerTeamId, 1);
  });
}

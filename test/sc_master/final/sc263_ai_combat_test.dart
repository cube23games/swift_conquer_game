import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/ai/ai_combat_planner.dart';
import 'package:swift_conquer_game/sc_master/ai/ai_perception.dart';
import 'package:swift_conquer_game/sc_master/core/id/entity_id.dart';

void main() {
  test('SC-263 AI prioritizes enemy buildings', () {
    const perception = AiPerception(
      friendlyUnits: [EntityId(1)],
      enemyUnits: [EntityId(2)],
      friendlyBuildings: [],
      enemyBuildings: [EntityId(3)],
    );
    expect(const AiCombatPlanner().decide(perception).target,
        const EntityId(3));
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/core/id/entity_id.dart';
import 'package:swift_conquer_game/sc_master/core/math/vec2.dart';
import 'package:swift_conquer_game/sc_master/economy/ore_field.dart';

void main() {
  test('SC-232 ore cannot be harvested twice', () {
    final ore = OreField(
      id: const EntityId(1), position: Vec2.zero, remaining: 50);
    expect(ore.harvest(40), 40);
    expect(ore.harvest(40), 10);
    expect(ore.depleted, isTrue);
  });
}

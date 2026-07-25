import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/core/math/vec2.dart';
import 'package:swift_conquer_game/sc_master/orders/attack_command.dart';
import 'package:swift_conquer_game/sc_master/orders/attack_order_service.dart';
import 'package:swift_conquer_game/sc_master/world/world_state.dart';

void main() {
  test('SC-227 attack service rejects friendly targets', () {
    final world = WorldState();
    final attacker = world.spawnUnit(
      teamId: 1, archetype: 'tank', position: Vec2.zero);
    final friend = world.spawnUnit(
      teamId: 1, archetype: 'tank', position: const Vec2(1, 1));
    final changed = const AttackOrderService().apply(world, AttackCommand(
      tick: 1, playerId: 1, attackers: [attacker], target: friend));
    expect(changed, 0);
  });
}

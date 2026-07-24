import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/core/math/vec2.dart';
import 'package:swift_conquer_game/sc_master/orders/move_command.dart';
import 'package:swift_conquer_game/sc_master/orders/move_order_service.dart';
import 'package:swift_conquer_game/sc_master/world/world_state.dart';

void main() {
  test('SC-223 move service rejects enemy units', () {
    final world = WorldState();
    final friendly = world.spawnUnit(
      teamId: 1, archetype: 'tank', position: Vec2.zero);
    final enemy = world.spawnUnit(
      teamId: 2, archetype: 'tank', position: Vec2.zero);
    final changed = const MoveOrderService().apply(world, MoveCommand(
      tick: 1, playerId: 1, units: [friendly, enemy],
      destination: const Vec2(50, 50),
    ));
    expect(changed, 1);
    expect(world.units[enemy]!.moveTarget, isNull);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/core/math/vec2.dart';
import 'package:swift_conquer_game/sc_master/engineer/infiltration_service.dart';
import 'package:swift_conquer_game/sc_master/world/world_state.dart';

void main() {
  test('SC-246 sabotage requires complete progress', () {
    final world = WorldState();
    final engineer = world.spawnUnit(
      teamId: 1, archetype: 'engineer', position: Vec2.zero);
    final target = world.spawnBuilding(
      teamId: 2, archetype: 'power_plant', position: Vec2.zero);
    final service = InfiltrationService();
    expect(service.apply(
      world: world,
      engineerId: engineer,
      buildingId: target,
      mode: InfiltrationMode.sabotage,
      amount: 50,
    ).completed, isFalse);
    expect(service.apply(
      world: world,
      engineerId: engineer,
      buildingId: target,
      mode: InfiltrationMode.sabotage,
      amount: 50,
    ).completed, isTrue);
    expect(world.buildings[target]!.powered, isFalse);
  });
}

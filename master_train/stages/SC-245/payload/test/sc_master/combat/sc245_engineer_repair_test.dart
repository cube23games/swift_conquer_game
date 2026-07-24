import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/core/math/vec2.dart';
import 'package:swift_conquer_game/sc_master/engineer/repair_service.dart';
import 'package:swift_conquer_game/sc_master/world/world_state.dart';

void main() {
  test('SC-245 only three engineers contribute', () {
    final world = WorldState();
    final building = world.spawnBuilding(
      teamId: 1, archetype: 'hq', position: Vec2.zero, health: 100);
    world.buildings[building]!.health = 10;
    final engineers = List.generate(4, (_) => world.spawnUnit(
      teamId: 1, archetype: 'engineer', position: Vec2.zero));
    final repaired = const RepairService().repairBuilding(
      world: world,
      buildingId: building,
      engineerIds: engineers,
      mode: RepairMode.engineers,
      pointsPerEngineer: 4,
    );
    expect(repaired, 12);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/game/buildings/building_type.dart';
import 'package:swift_conquer_game/game/core/world_state.dart';
import 'package:swift_conquer_game/game/math/vec2.dart';
import 'package:swift_conquer_game/game/production/facility_production_queues.dart';
import 'package:swift_conquer_game/game/production/primary_production_registry.dart';
import 'package:swift_conquer_game/game/production/production_unit_type.dart';

void main() {
  group('FacilityProductionQueues', () {
    test('each production building owns an independent queue', () {
      final world = WorldState();
      final queues = FacilityProductionQueues();
      final first = world.spawnBuilding(
        BuildingType.barracks,
        const Vec2(100, 100),
        teamId: 1,
      );
      final second = world.spawnBuilding(
        BuildingType.barracks,
        const Vec2(200, 100),
        teamId: 1,
      );

      expect(
        queues.enqueue(
          world: world,
          buildingId: first,
          item: ProductionUnitType.rifleInfantry,
        ),
        isTrue,
      );
      expect(
        queues.enqueue(
          world: world,
          buildingId: second,
          item: ProductionUnitType.rifleInfantry,
        ),
        isTrue,
      );

      expect(queues.queueCount(first), 1);
      expect(queues.queueCount(second), 1);
    });

    test('changing primary does not transfer existing orders', () {
      final world = WorldState();
      final registry = PrimaryProductionRegistry();
      final queues = FacilityProductionQueues();

      final first = world.spawnBuilding(
        BuildingType.warFactory,
        const Vec2(100, 100),
        teamId: 1,
      );
      final second = world.spawnBuilding(
        BuildingType.warFactory,
        const Vec2(200, 100),
        teamId: 1,
      );

      expect(
        registry.primaryFor(
          world: world,
          teamId: 1,
          type: BuildingType.warFactory,
        ),
        first,
      );
      expect(
        queues.enqueue(
          world: world,
          buildingId: first,
          item: ProductionUnitType.tank,
        ),
        isTrue,
      );

      expect(
        registry.makePrimary(
          world: world,
          teamId: 1,
          type: BuildingType.warFactory,
          buildingId: second,
        ),
        isTrue,
      );
      expect(
        queues.enqueue(
          world: world,
          buildingId: second,
          item: ProductionUnitType.tank,
        ),
        isTrue,
      );

      expect(queues.queueCount(first), 1);
      expect(queues.queueCount(second), 1);
    });

    test('ready order waits until explicitly consumed', () {
      final world = WorldState();
      final queues = FacilityProductionQueues();
      final barracks = world.spawnBuilding(
        BuildingType.barracks,
        const Vec2(100, 100),
        teamId: 1,
      );

      queues.enqueue(
        world: world,
        buildingId: barracks,
        item: ProductionUnitType.rifleInfantry,
      );
      queues.tick(
        dt: ProductionUnitType.rifleInfantry.prototypeBuildSeconds + 1,
        world: world,
      );

      final ready = queues.readySnapshots(world: world);
      expect(ready, hasLength(1));
      expect(ready.single.ready, isTrue);
      expect(ready.single.progress, 1);

      queues.tick(dt: 100, world: world);
      expect(queues.readySnapshots(world: world), hasLength(1));
      expect(queues.consumeReady(barracks), isTrue);
      expect(queues.queueCount(barracks), 0);
    });

    test('queue capacity and producer type are enforced', () {
      final world = WorldState();
      final queues = FacilityProductionQueues(capacity: 2);
      final barracks = world.spawnBuilding(
        BuildingType.barracks,
        const Vec2(100, 100),
        teamId: 1,
      );

      expect(
        queues.enqueue(
          world: world,
          buildingId: barracks,
          item: ProductionUnitType.tank,
        ),
        isFalse,
      );

      expect(
        queues.enqueue(
          world: world,
          buildingId: barracks,
          item: ProductionUnitType.rifleInfantry,
        ),
        isTrue,
      );
      expect(
        queues.enqueue(
          world: world,
          buildingId: barracks,
          item: ProductionUnitType.rifleInfantry,
        ),
        isTrue,
      );
      expect(
        queues.enqueue(
          world: world,
          buildingId: barracks,
          item: ProductionUnitType.rifleInfantry,
        ),
        isFalse,
      );
    });

    test('destroyed building removes its queue', () {
      final world = WorldState();
      final queues = FacilityProductionQueues();
      final factory = world.spawnBuilding(
        BuildingType.warFactory,
        const Vec2(100, 100),
        teamId: 1,
      );

      queues.enqueue(
        world: world,
        buildingId: factory,
        item: ProductionUnitType.tank,
      );
      world.destroy(factory);
      queues.tick(dt: 1, world: world);

      expect(queues.queueCount(factory), 0);
      expect(queues.snapshotsForWorld(world: world), isEmpty);
    });
  });
}

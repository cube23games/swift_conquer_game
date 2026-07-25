import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/game/buildings/building_type.dart';
import 'package:swift_conquer_game/game/core/world_state.dart';
import 'package:swift_conquer_game/game/math/vec2.dart';
import 'package:swift_conquer_game/game/production/primary_production_registry.dart';

void main() {
  group('PrimaryProductionRegistry', () {
    test('first Barracks stays primary until player changes it', () {
      final world = WorldState();
      final registry = PrimaryProductionRegistry();

      final first = world.spawnBuilding(
        BuildingType.barracks,
        const Vec2(100, 100),
        teamId: 1,
      );
      expect(
        registry.primaryFor(
          world: world,
          teamId: 1,
          type: BuildingType.barracks,
        ),
        first,
      );

      final second = world.spawnBuilding(
        BuildingType.barracks,
        const Vec2(200, 100),
        teamId: 1,
      );
      expect(
        registry.primaryFor(
          world: world,
          teamId: 1,
          type: BuildingType.barracks,
        ),
        first,
      );

      expect(
        registry.makePrimary(
          world: world,
          teamId: 1,
          type: BuildingType.barracks,
          buildingId: second,
        ),
        isTrue,
      );
      expect(
        registry.primaryFor(
          world: world,
          teamId: 1,
          type: BuildingType.barracks,
        ),
        second,
      );
    });

    test('destroyed primary falls back to oldest surviving facility', () {
      final world = WorldState();
      final registry = PrimaryProductionRegistry();

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
      final third = world.spawnBuilding(
        BuildingType.warFactory,
        const Vec2(300, 100),
        teamId: 1,
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

      world.destroy(second);
      expect(
        registry.primaryFor(
          world: world,
          teamId: 1,
          type: BuildingType.warFactory,
        ),
        first,
      );
      expect(
        registry.countFor(
          world: world,
          teamId: 1,
          type: BuildingType.warFactory,
        ),
        2,
      );
      expect(third, isNot(first));
    });

    test('teams keep separate primary facilities', () {
      final world = WorldState();
      final registry = PrimaryProductionRegistry();

      final friendly = world.spawnBuilding(
        BuildingType.barracks,
        const Vec2(100, 100),
        teamId: 1,
      );
      final enemy = world.spawnBuilding(
        BuildingType.barracks,
        const Vec2(200, 100),
        teamId: 2,
      );

      expect(
        registry.primaryFor(
          world: world,
          teamId: 1,
          type: BuildingType.barracks,
        ),
        friendly,
      );
      expect(
        registry.primaryFor(
          world: world,
          teamId: 2,
          type: BuildingType.barracks,
        ),
        enemy,
      );
    });

    test('non-production building types are not accepted', () {
      final world = WorldState();
      final registry = PrimaryProductionRegistry();
      final refinery = world.spawnBuilding(
        BuildingType.refinery,
        const Vec2(100, 100),
        teamId: 1,
      );

      expect(
        registry.primaryFor(
          world: world,
          teamId: 1,
          type: BuildingType.refinery,
        ),
        isNull,
      );
      expect(
        registry.makePrimary(
          world: world,
          teamId: 1,
          type: BuildingType.refinery,
          buildingId: refinery,
        ),
        isFalse,
      );
    });
  });
}

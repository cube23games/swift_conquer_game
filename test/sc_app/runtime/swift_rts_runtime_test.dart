import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_app/catalog/rts_catalog.dart';
import 'package:swift_conquer_game/sc_app/runtime/swift_rts_runtime.dart';
import 'package:swift_conquer_game/sc_master/core/math/vec2.dart';
import 'package:swift_conquer_game/sc_master/integrity/integrity_monitor.dart';

void tickMany(SwiftRtsRuntime runtime, int ticks) {
  for (var i = 0; i < ticks; i += 1) {
    runtime.tick(1 / 60);
  }
}

void main() {
  group('SwiftRtsRuntime SC-300 application bridge', () {
    test('starts with explicit Mobile HQ and does not auto-deploy', () {
      final runtime = SwiftRtsRuntime();

      expect(runtime.playerMobileHq, isNotNull);
      expect(
        runtime.ownsBuilding(SwiftRtsRuntime.playerTeamId, 'hq'),
        isFalse,
      );
      expect(
        runtime.wallet(SwiftRtsRuntime.playerTeamId).balance,
        SwiftRtsCatalog.prototypeStartingCredits,
      );
    });

    test('HQ deploy unlocks queued structure construction and placement', () {
      final runtime = SwiftRtsRuntime();
      expect(runtime.deployPlayerHq(), isTrue);

      final before =
          runtime.wallet(SwiftRtsRuntime.playerTeamId).balance;
      expect(
        runtime.queueStructure(
          SwiftRtsRuntime.playerTeamId,
          'power_plant',
        ),
        isTrue,
      );
      expect(
        runtime.wallet(SwiftRtsRuntime.playerTeamId).balance,
        before - SwiftRtsCatalog.building('power_plant').prototypeCost,
      );

      tickMany(
        runtime,
        SwiftRtsCatalog.building('power_plant').prototypeBuildTicks,
      );
      expect(
        runtime
            .structureQueueSnapshot(SwiftRtsRuntime.playerTeamId)
            .ready,
        isTrue,
      );

      expect(
        runtime.placeReadyStructure(
          teamId: SwiftRtsRuntime.playerTeamId,
          position: const Vec2(600, 290),
        ),
        isTrue,
      );
      expect(
        runtime.ownsBuilding(
          SwiftRtsRuntime.playerTeamId,
          'power_plant',
        ),
        isTrue,
      );
    });

    test('new unit orders follow Primary but old queues stay put', () {
      final runtime = SwiftRtsRuntime();
      final first = runtime.world.spawnBuilding(
        teamId: SwiftRtsRuntime.playerTeamId,
        archetype: 'barracks',
        position: const Vec2(420, 400),
      );
      final second = runtime.world.spawnBuilding(
        teamId: SwiftRtsRuntime.playerTeamId,
        archetype: 'barracks',
        position: const Vec2(300, 400),
      );

      expect(
        runtime.primaryFacilities.primaryFor(
          world: runtime.world,
          teamId: SwiftRtsRuntime.playerTeamId,
          archetype: 'barracks',
        ),
        first,
      );

      expect(
        runtime.queueUnit(
          teamId: SwiftRtsRuntime.playerTeamId,
          archetype: 'infantry',
        ),
        isTrue,
      );
      expect(runtime.facilityQueueSnapshot(first)?.count, 1);
      expect(runtime.facilityQueueSnapshot(second), isNull);

      expect(runtime.makePrimary(second), isTrue);
      expect(
        runtime.queueUnit(
          teamId: SwiftRtsRuntime.playerTeamId,
          archetype: 'infantry',
        ),
        isTrue,
      );

      expect(runtime.facilityQueueSnapshot(first)?.count, 1);
      expect(runtime.facilityQueueSnapshot(second)?.count, 1);
    });

    test('completed production holds READY while every exit is blocked', () {
      final runtime = SwiftRtsRuntime();
      runtime.world.spawnBuilding(
        teamId: SwiftRtsRuntime.playerTeamId,
        archetype: 'power_plant',
        position: const Vec2(200, 200),
      );
      final barracks = runtime.world.spawnBuilding(
        teamId: SwiftRtsRuntime.playerTeamId,
        archetype: 'barracks',
        position: const Vec2(300, 300),
      );

      for (final point in const <Vec2>[
        Vec2(382, 300),
        Vec2(382, 258),
        Vec2(382, 342),
        Vec2(218, 300),
        Vec2(300, 218),
        Vec2(300, 382),
        Vec2(424, 258),
        Vec2(424, 342),
      ]) {
        runtime.world.spawnUnit(
          teamId: SwiftRtsRuntime.playerTeamId,
          archetype: 'infantry',
          position: point,
          health: 30,
        );
      }

      expect(
        runtime.queueUnit(
          teamId: SwiftRtsRuntime.playerTeamId,
          archetype: 'infantry',
        ),
        isTrue,
      );

      tickMany(
        runtime,
        SwiftRtsCatalog.unit('infantry').prototypeBuildTicks + 30,
      );

      final snapshot = runtime.facilityQueueSnapshot(barracks);
      expect(snapshot, isNotNull);
      expect(snapshot!.ready, isTrue);
      expect(snapshot.count, 1);
    });

    test('enemy spy compromises source and purge uses locked 10 percent', () {
      final runtime = SwiftRtsRuntime();
      final source = runtime.world.spawnBuilding(
        teamId: SwiftRtsRuntime.playerTeamId,
        archetype: 'refinery',
        position: const Vec2(500, 400),
      );
      final spy = runtime.world.spawnUnit(
        teamId: SwiftRtsRuntime.enemyTeamId,
        archetype: 'spy',
        position: const Vec2(470, 400),
        health: 20,
      );

      runtime.assignSpyTarget(spyId: spy, buildingId: source);
      runtime.tick(1 / 60);

      expect(runtime.isCompromised(source), isTrue);
      expect(
        runtime.stolenTech.stolenFor(SwiftRtsRuntime.enemyTeamId),
        contains('refinery'),
      );

      final before =
          runtime.wallet(SwiftRtsRuntime.playerTeamId).balance;
      expect(runtime.purgeCompromisedBuilding(source), isTrue);
      final expectedRefund =
          (SwiftRtsCatalog.building('refinery').prototypeCost * 0.10)
              .floor();

      expect(
        runtime.wallet(SwiftRtsRuntime.playerTeamId).balance,
        before + expectedRefund,
      );
      expect(
        runtime.stolenTech.stolenFor(SwiftRtsRuntime.enemyTeamId),
        isEmpty,
      );
    });

    test('ordinary building sale remains disabled until rate is canon', () {
      final runtime = SwiftRtsRuntime();
      final building = runtime.world.spawnBuilding(
        teamId: SwiftRtsRuntime.playerTeamId,
        archetype: 'power_plant',
        position: const Vec2(500, 400),
      );

      expect(runtime.ordinarySellAvailable(building), isFalse);
    });

    test('advanced tech charges prototype special power only with power', () {
      final runtime = SwiftRtsRuntime();
      runtime.world.spawnBuilding(
        teamId: SwiftRtsRuntime.playerTeamId,
        archetype: 'power_plant',
        position: const Vec2(300, 300),
      );
      runtime.world.spawnBuilding(
        teamId: SwiftRtsRuntime.playerTeamId,
        archetype: 'advanced_tech',
        position: const Vec2(400, 300),
      );

      tickMany(
        runtime,
        SwiftRtsCatalog.prototypeSpecialPower.prototypeChargeTicks + 30,
      );

      expect(
        runtime.specialPowers[SwiftRtsRuntime.playerTeamId]?.ready,
        isTrue,
      );
    });

    test('authoritative hash feeds the integrity monitor', () {
      final runtime = SwiftRtsRuntime();
      tickMany(runtime, 60);

      final clean = runtime.inspectRemoteHash(
        teamId: SwiftRtsRuntime.playerTeamId,
        reportedHash: runtime.authoritativeHash,
      );
      expect(clean.response, IntegrityResponse.none);

      final mismatch = runtime.inspectRemoteHash(
        teamId: SwiftRtsRuntime.playerTeamId,
        reportedHash: runtime.authoritativeHash + 1,
      );
      expect(mismatch.response, IntegrityResponse.markSuspected);
    });
  });
}

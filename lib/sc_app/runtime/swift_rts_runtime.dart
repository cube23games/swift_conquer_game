import 'dart:math' as math;

import '../../sc_master/ai/ai_combat_planner.dart';
import '../../sc_master/ai/ai_economy_planner.dart';
import '../../sc_master/ai/ai_perception.dart';
import '../../sc_master/ai/deterministic_ai.dart';
import '../../sc_master/combat/combat_resolver.dart';
import '../../sc_master/combat/damage_packet.dart';
import '../../sc_master/combat/target_selector.dart';
import '../../sc_master/construction/build_rule.dart';
import '../../sc_master/construction/building_lifecycle.dart';
import '../../sc_master/control/formation_planner.dart';
import '../../sc_master/control/selection_state.dart';
import '../../sc_master/core/id/entity_id.dart';
import '../../sc_master/core/math/vec2.dart';
import '../../sc_master/core/replay/replay_event.dart';
import '../../sc_master/core/replay/replay_journal.dart';
import '../../sc_master/core/replay/replay_verifier.dart';
import '../../sc_master/core/replay/state_hasher.dart';
import '../../sc_master/economy/harvester_state.dart';
import '../../sc_master/economy/ore_field.dart';
import '../../sc_master/economy/silo_storage.dart';
import '../../sc_master/economy/wallet.dart';
import '../../sc_master/engineer/infiltration_service.dart';
import '../../sc_master/engineer/repair_service.dart';
import '../../sc_master/integrity/integrity_monitor.dart';
import '../../sc_master/map/map_runtime.dart';
import '../../sc_master/map/map_spec.dart';
import '../../sc_master/match/match_rules.dart';
import '../../sc_master/match/storm_ring.dart';
import '../../sc_master/match/victory_condition.dart';
import '../../sc_master/orders/attack_command.dart';
import '../../sc_master/orders/attack_order_service.dart';
import '../../sc_master/orders/move_command.dart';
import '../../sc_master/orders/move_order_service.dart';
import '../../sc_master/power/power_grid.dart';
import '../../sc_master/power/power_penalties.dart';
import '../../sc_master/spy/tech_access.dart';
import '../../sc_master/superweapon/superweapon_state.dart';
import '../../sc_master/world/building_state.dart';
import '../../sc_master/world/unit_state.dart';
import '../../sc_master/world/world_state.dart';
import '../catalog/rts_catalog.dart';
import 'primary_facility_registry.dart';
import 'runtime_queue.dart';
import 'runtime_snapshot.dart';
import 'visibility_grid.dart';

enum EngineerTaskMode {
  repair,
  capture,
  sabotage,
}

final class CompromiseRecord {
  final int infiltratingTeamId;
  final String stolenTechId;

  const CompromiseRecord({
    required this.infiltratingTeamId,
    required this.stolenTechId,
  });
}

final class SwiftRtsRuntime {
  static const int playerTeamId = 1;
  static const int enemyTeamId = 2;

  final int unitCap;

  final WorldState world = WorldState();
  final SelectionState selection = SelectionState();
  final PrimaryFacilityRegistry primaryFacilities =
      PrimaryFacilityRegistry();

  final Map<int, Wallet> _wallets = <int, Wallet>{};
  final Map<int, PowerGrid> _power = <int, PowerGrid>{};
  final Map<int, SiloStorage> _storage = <int, SiloStorage>{};
  final Map<int, RuntimeBuildQueue> _structureQueues =
      <int, RuntimeBuildQueue>{};
  final Map<EntityId, RuntimeBuildQueue> _facilityQueues =
      <EntityId, RuntimeBuildQueue>{};
  final Map<EntityId, Vec2> rallyPoints = <EntityId, Vec2>{};
  final Map<EntityId, HarvesterState> harvesters =
      <EntityId, HarvesterState>{};
  final List<OreField> oreFields = <OreField>[];

  final TechAccess stolenTech = TechAccess();
  final Map<EntityId, CompromiseRecord> compromisedBuildings =
      <EntityId, CompromiseRecord>{};
  final Map<EntityId, EntityId> _spyTargets = <EntityId, EntityId>{};
  final Map<EntityId, EntityId> _engineerTargets = <EntityId, EntityId>{};
  final Map<EntityId, EngineerTaskMode> _engineerModes =
      <EntityId, EngineerTaskMode>{};

  final Map<int, SuperweaponState> specialPowers =
      <int, SuperweaponState>{};
  final ReplayJournal replay = ReplayJournal();
  final IntegrityMonitor integrity = IntegrityMonitor();

  final MatchRules matchRules = const MatchRules(
    tickRate: 60,
    targetMinutes: 15,
    suddenDeathStartMinutes: 12,
  );
  final StormRing storm = const StormRing(
    initialRadius: 720,
    minimumRadius: 180,
    shrinkPerTick: 0.055,
  );

  final BuildRule buildRule = const BuildRule(radius: 120);
  final CombatResolver combat = const CombatResolver();
  final TargetSelector targets = const TargetSelector();
  final MoveOrderService moveOrders = const MoveOrderService();
  final AttackOrderService attackOrders = const AttackOrderService();
  final FormationPlanner formation = const FormationPlanner();
  final RepairService repair = const RepairService();
  final InfiltrationService infiltration = InfiltrationService();
  final VictoryCondition victory = const VictoryCondition();
  final ReplayVerifier replayVerifier = const ReplayVerifier();
  final StateHasher hasher = const StateHasher();

  final DeterministicAi enemyAi = DeterministicAi(
    seed: 230023,
    thinkEveryTicks: 60,
  );
  final AiEconomyPlanner aiEconomy = const AiEconomyPlanner();
  final AiCombatPlanner aiCombat = const AiCombatPlanner();

  late final MapSpec mapSpec;
  late final MapRuntime mapRuntime;
  late final VisibilityGrid visibility;

  EntityId? playerMobileHq;
  bool specialPowerTargeting = false;
  EngineerTaskMode engineerMode = EngineerTaskMode.repair;

  String status = 'Initializing SwiftConquer...';
  VictoryResult matchResult = const VictoryResult();
  int authoritativeHash = 0;

  final Map<EntityId, int> _lastAttackTick = <EntityId, int>{};
  final Map<EntityId, int> _powerOutageUntilTick = <EntityId, int>{};
  final Set<EntityId> manualRepairEnabled = <EntityId>{};
  final Set<int> flaggedCheaterTeams = <int>{};

  SwiftRtsRuntime({
    this.unitCap = SwiftRtsCatalog.standardUnitCap,
  }) {
    mapSpec = const MapSpec(
      id: 'swiftconquer_live_01',
      width: 1200,
      height: 800,
      cellSize: SwiftRtsCatalog.cellSize,
      spawns: <Vec2>[
        Vec2(600, 400),
        Vec2(1040, 620),
      ],
    );
    mapRuntime = MapRuntime(mapSpec);
    visibility = VisibilityGrid(
      worldWidth: mapSpec.width,
      worldHeight: mapSpec.height,
    );
    _bootstrap();
  }

  Wallet wallet(int teamId) {
    return _wallets.putIfAbsent(
      teamId,
      () => Wallet(balance: SwiftRtsCatalog.prototypeStartingCredits),
    );
  }

  PowerGrid power(int teamId) {
    return _power.putIfAbsent(teamId, () => PowerGrid());
  }

  SiloStorage storage(int teamId) {
    return _storage.putIfAbsent(teamId, () => SiloStorage());
  }

  RuntimeBuildQueue structureQueue(int teamId) {
    return _structureQueues.putIfAbsent(
      teamId,
      () => RuntimeBuildQueue(limit: SwiftRtsCatalog.prototypeQueueLimit),
    );
  }

  RuntimeBuildQueue facilityQueue(EntityId buildingId) {
    return _facilityQueues.putIfAbsent(
      buildingId,
      () => RuntimeBuildQueue(limit: SwiftRtsCatalog.prototypeQueueLimit),
    );
  }

  RuntimeQueueSnapshot structureQueueSnapshot(int teamId) {
    return structureQueue(teamId).snapshot;
  }

  RuntimeQueueSnapshot? facilityQueueSnapshot(EntityId buildingId) {
    final queue = _facilityQueues[buildingId];
    return queue?.snapshot;
  }

  RuntimeQueueSnapshot? primaryQueueSnapshot(
    int teamId,
    String producer,
  ) {
    final id = primaryFacilities.primaryFor(
      world: world,
      teamId: teamId,
      archetype: producer,
    );
    if (id == null) return null;
    return _facilityQueues[id]?.snapshot;
  }

  Set<String> ownedTech(int teamId) {
    final tech = <String>{
      for (final building in world.buildings.values)
        if (building.alive && building.teamId == teamId)
          building.archetype,
    };
    tech.addAll(stolenTech.stolenFor(teamId));
    return tech;
  }

  bool prerequisitesMet(int teamId, Set<String> prerequisites) {
    final available = ownedTech(teamId);
    return prerequisites.every(available.contains);
  }

  bool ownsBuilding(int teamId, String archetype) {
    return world.buildings.values.any((building) =>
        building.alive &&
        building.teamId == teamId &&
        building.archetype == archetype);
  }

  List<BuildingState> buildingsForTeam(
    int teamId, {
    String? archetype,
  }) {
    final result = world.buildings.values
        .where((building) =>
            building.alive &&
            building.teamId == teamId &&
            (archetype == null || building.archetype == archetype))
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    return result;
  }

  List<UnitState> unitsForTeam(
    int teamId, {
    String? archetype,
  }) {
    final result = world.units.values
        .where((unit) =>
            unit.alive &&
            unit.teamId == teamId &&
            (archetype == null || unit.archetype == archetype))
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    return result;
  }

  int get matchSeconds => world.tick ~/ matchRules.tickRate;

  double get stormRadius {
    if (!matchRules.suddenDeathActive(world.tick)) {
      return storm.initialRadius;
    }
    return storm.radiusAt(world.tick - matchRules.suddenDeathTick);
  }

  Map<String, Object?> snapshot() {
    final base = buildRuntimeSnapshot(
      world: world,
      credits: <int, int>{
        for (final entry in _wallets.entries) entry.key: entry.value.balance,
      },
      powerProduced: <int, int>{
        for (final entry in _power.entries) entry.key: entry.value.produced,
      },
      powerDemand: <int, int>{
        for (final entry in _power.entries) entry.key: entry.value.demand,
      },
      structureQueues: <int, RuntimeQueueSnapshot>{
        for (final entry in _structureQueues.entries)
          entry.key: entry.value.snapshot,
      },
      tick: world.tick,
    );

    Map<String, Object?> queueJson(RuntimeQueueSnapshot queue) =>
        <String, Object?>{
          'current': queue.current?.archetype,
          'count': queue.count,
          'progress': queue.progress,
          'ready': queue.ready,
          'limit': queue.limit,
        };

    final facilityIds = _facilityQueues.keys.toList()..sort();
    final harvesterIds = harvesters.keys.toList()..sort();
    final rallyIds = rallyPoints.keys.toList()..sort();
    final compromisedIds = compromisedBuildings.keys.toList()..sort();
    final manualRepairIds = manualRepairEnabled.toList()..sort();
    final flaggedTeams = flaggedCheaterTeams.toList()..sort();
    final ore = oreFields.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    final specialTeams = specialPowers.keys.toList()..sort();

    base['facilityQueues'] = <Object?>[
      for (final id in facilityIds)
        <String, Object?>{
          'building': id.value,
          ...queueJson(_facilityQueues[id]!.snapshot),
        },
    ];
    base['harvesters'] = <Object?>[
      for (final id in harvesterIds)
        <String, Object?>{
          'unit': id.value,
          'cargo': harvesters[id]!.cargo,
          'capacity': harvesters[id]!.capacity,
        },
    ];
    base['ore'] = <Object?>[
      for (final field in ore)
        <String, Object?>{
          'id': field.id.value,
          'x': field.position.x,
          'y': field.position.y,
          'remaining': field.remaining,
        },
    ];
    base['rallyPoints'] = <Object?>[
      for (final id in rallyIds)
        <String, Object?>{
          'building': id.value,
          'point': rallyPoints[id]!.toJson(),
        },
    ];
    base['compromised'] = <Object?>[
      for (final id in compromisedIds)
        <String, Object?>{
          'building': id.value,
          'infiltratingTeam':
              compromisedBuildings[id]!.infiltratingTeamId,
          'stolenTech': compromisedBuildings[id]!.stolenTechId,
        },
    ];
    base['manualRepair'] =
        manualRepairIds.map((id) => id.value).toList();
    base['flaggedCheaterTeams'] = flaggedTeams;
    base['specialPowers'] = <Object?>[
      for (final teamId in specialTeams)
        <String, Object?>{
          'team': teamId,
          'id': specialPowers[teamId]!.id,
          'progress': specialPowers[teamId]!.progress,
          'ready': specialPowers[teamId]!.ready,
        },
    ];
    base['primaryFacilities'] = <Object?>[
      for (final archetype in const <String>[
        'barracks',
        'war_factory',
        'airfield',
        'naval_yard',
      ])
        <String, Object?>{
          'team': playerTeamId,
          'archetype': archetype,
          'building': primaryFacilities
              .primaryFor(
                world: world,
                teamId: playerTeamId,
                archetype: archetype,
              )
              ?.value,
        },
    ];
    base['unitCap'] = unitCap;
    base['stormRadius'] = stormRadius;

    return base;
  }

  String get replayJson => replay.encode();

  IntegrityFinding inspectRemoteHash({
    required int teamId,
    required int reportedHash,
  }) {
    final finding = integrity.inspect(
      teamId: teamId,
      reportedHash: reportedHash,
      authoritativeHash: authoritativeHash,
    );
    _applyIntegrityFinding(finding);
    return finding;
  }

  void tick(double dt) {
    if (dt <= 0 || matchResult.finished) return;
    world.tick += 1;

    if (world.tick % 15 == 0) {
      _recalculatePower();
      _recalculateStorageCapacity();
    }

    _tickStructureQueues();
    _tickFacilityQueues();
    _tickPendingInfiltration();
    _tickManualRepairs();
    _tickLowPowerBreakdown();
    _tickHarvesters();
    _tickMovement(dt);
    _tickCombat();
    _tickSpecialPowers();
    _tickAi();
    _tickStorm();

    visibility.updateForTeam(world, playerTeamId);

    matchResult = victory.evaluate(world);
    if (matchResult.finished) {
      status = matchResult.draw
          ? 'Match ended in a draw.'
          : 'Team ${matchResult.winnerTeamId} wins.';
    }

    if (world.tick % 60 == 0) {
      authoritativeHash = hasher.hashJson(snapshot());
    }
  }

  void _bootstrap() {
    wallet(playerTeamId);
    wallet(enemyTeamId);
    power(playerTeamId);
    power(enemyTeamId);
    storage(playerTeamId);
    storage(enemyTeamId);
    structureQueue(playerTeamId);
    structureQueue(enemyTeamId);

    playerMobileHq = world.spawnUnit(
      teamId: playerTeamId,
      archetype: 'mobile_hq_center',
      position: const Vec2(600, 400),
      health: 100,
    );
    selection.replaceWith(<EntityId>[playerMobileHq!]);

    _spawnBuilding(
      teamId: enemyTeamId,
      archetype: 'hq',
      position: const Vec2(1040, 620),
      health: 300,
    );
    _spawnBuilding(
      teamId: enemyTeamId,
      archetype: 'power_plant',
      position: const Vec2(930, 610),
      health: 160,
    );
    _spawnBuilding(
      teamId: enemyTeamId,
      archetype: 'refinery',
      position: const Vec2(1010, 510),
      health: 200,
    );
    _spawnBuilding(
      teamId: enemyTeamId,
      archetype: 'barracks',
      position: const Vec2(900, 500),
      health: 170,
    );
    _spawnBuilding(
      teamId: enemyTeamId,
      archetype: 'war_factory',
      position: const Vec2(1040, 410),
      health: 240,
    );

    final aiTank1 = _spawnUnit(
      teamId: enemyTeamId,
      archetype: 'tank',
      position: const Vec2(940, 360),
    );
    final aiTank2 = _spawnUnit(
      teamId: enemyTeamId,
      archetype: 'tank',
      position: const Vec2(1010, 350),
    );
    world.units[aiTank1]?.moveTarget = const Vec2(760, 430);
    world.units[aiTank2]?.moveTarget = const Vec2(760, 470);

    _seedOre(const Vec2(430, 260), 9000);
    _seedOre(const Vec2(720, 230), 8000);
    _seedOre(const Vec2(820, 590), 9000);
    _seedOre(const Vec2(270, 600), 7000);

    specialPowers[playerTeamId] = SuperweaponState(
      id: SwiftRtsCatalog.prototypeSpecialPower.id,
      chargeTicks: SwiftRtsCatalog.prototypeSpecialPower.prototypeChargeTicks,
    );
    specialPowers[enemyTeamId] = SuperweaponState(
      id: SwiftRtsCatalog.prototypeSpecialPower.id,
      chargeTicks: SwiftRtsCatalog.prototypeSpecialPower.prototypeChargeTicks,
    );

    _recalculatePower();
    _recalculateStorageCapacity();
    visibility.updateForTeam(world, playerTeamId);
    authoritativeHash = hasher.hashJson(snapshot());

    status =
        'Move the central Mobile HQ Center, then deploy Headquarters.';
  }

  void _seedOre(Vec2 position, int amount) {
    final id = world.entities.create(teamId: 0, kind: 'ore');
    oreFields.add(
      OreField(
        id: id,
        position: position,
        remaining: amount,
      ),
    );
  }

  EntityId _spawnBuilding({
    required int teamId,
    required String archetype,
    required Vec2 position,
    int? health,
  }) {
    final blueprint = SwiftRtsCatalog.buildingOrNull(archetype);
    final id = world.spawnBuilding(
      teamId: teamId,
      archetype: archetype,
      position: position,
      health: health ?? _prototypeBuildingHealth(blueprint),
    );
    if (blueprint != null && PrimaryFacilityRegistry.supports(archetype)) {
      primaryFacilities.primaryFor(
        world: world,
        teamId: teamId,
        archetype: archetype,
      );
    }
    return id;
  }

  EntityId _spawnUnit({
    required int teamId,
    required String archetype,
    required Vec2 position,
  }) {
    final blueprint = SwiftRtsCatalog.unitOrNull(archetype);
    final id = world.spawnUnit(
      teamId: teamId,
      archetype: archetype,
      position: position,
      health: blueprint?.health ?? 100,
      domain: blueprint?.domain ?? UnitDomain.land,
    );
    if (archetype == 'harvester') {
      harvesters[id] = HarvesterState(unitId: id);
    }
    return id;
  }

  int _prototypeBuildingHealth(BuildingBlueprint? blueprint) {
    if (blueprint == null) return 200;
    if (blueprint.id == 'hq') return 300;
    return 120 + blueprint.footprintCols * blueprint.footprintRows * 20;
  }

  bool deployPlayerHq() {
    final mobile = playerMobileHq;
    if (mobile == null) return false;
    final hq = const BuildingLifecycle().deployMobileHq(world, mobile);
    if (hq == null) {
      status = 'HQ deployment unavailable.';
      return false;
    }
    playerMobileHq = null;
    selection.replaceWith(<EntityId>[hq]);
    replay.record(
      ReplayEvent(
        tick: world.tick,
        type: 'deploy_hq',
        payload: <String, Object?>{'building': hq.value},
      ),
    );
    status = 'Headquarters deployed. Structures lane unlocked.';
    visibility.updateForTeam(world, playerTeamId);
    return true;
  }

  bool queueStructure(int teamId, String archetype) {
    final blueprint = SwiftRtsCatalog.buildingOrNull(archetype);
    if (blueprint == null || blueprint.id == 'hq') return false;
    if (!ownsBuilding(teamId, 'hq')) {
      if (teamId == playerTeamId) {
        status = 'Deploy Headquarters before constructing buildings.';
      }
      return false;
    }
    if (!prerequisitesMet(teamId, blueprint.prerequisites)) {
      if (teamId == playerTeamId) {
        status = '${blueprint.label} prerequisites are not met.';
      }
      return false;
    }

    final order = RuntimeOrder(
      archetype: blueprint.id,
      label: blueprint.label,
      cost: blueprint.prototypeCost,
      buildTicks: blueprint.prototypeBuildTicks,
    );

    final queue = structureQueue(teamId);
    if (queue.snapshot.count >= queue.limit) {
      if (teamId == playerTeamId) {
        status = 'Structure queue is full.';
      }
      return false;
    }
    if (!_spend(teamId, order.cost)) {
      if (teamId == playerTeamId) {
        status = 'Insufficient credits for ${blueprint.label}.';
      }
      return false;
    }
    if (!queue.enqueue(order)) {
      wallet(teamId).credit(order.cost);
      if (teamId == playerTeamId) {
        status = 'Structure queue rejected ${blueprint.label}.';
      }
      return false;
    }

    replay.record(
      ReplayEvent(
        tick: world.tick,
        type: 'queue_structure',
        payload: <String, Object?>{
          'team': teamId,
          'archetype': archetype,
        },
      ),
    );
    if (teamId == playerTeamId) {
      status = '${blueprint.label} added to structure queue.';
    }
    return true;
  }

  RuntimeOrder? cancelLastStructure(int teamId) {
    final order = structureQueue(teamId).cancelLast();
    if (order != null) {
      wallet(teamId).credit(order.cost);
      status = '${order.label} cancelled and queued cost refunded.';
    }
    return order;
  }

  bool placeReadyStructure({
    required int teamId,
    required Vec2 position,
  }) {
    final queue = structureQueue(teamId);
    final order = queue.readyOrder;
    if (order == null) return false;

    final blueprint = SwiftRtsCatalog.buildingOrNull(order.archetype);
    if (blueprint == null) return false;
    if (!mapRuntime.contains(position) || mapRuntime.isBlocked(position)) {
      if (teamId == playerTeamId) {
        status = 'Cannot place ${blueprint.label} there.';
      }
      return false;
    }
    if (!buildRule.canBuild(
      world: world,
      teamId: teamId,
      position: position,
    )) {
      if (teamId == playerTeamId) {
        status = 'Build within the active base construction radius.';
      }
      return false;
    }
    if (!_placementClear(position, blueprint)) {
      if (teamId == playerTeamId) {
        status = '${blueprint.label} footprint is blocked.';
      }
      return false;
    }

    final id = _spawnBuilding(
      teamId: teamId,
      archetype: blueprint.id,
      position: position,
    );
    queue.acceptReady();
    _recalculatePower();
    _recalculateStorageCapacity();
    replay.record(
      ReplayEvent(
        tick: world.tick,
        type: 'place_structure',
        payload: <String, Object?>{
          'team': teamId,
          'building': id.value,
          'archetype': blueprint.id,
          'position': position.toJson(),
        },
      ),
    );
    if (teamId == playerTeamId) {
      status = '${blueprint.label} placed.';
    }
    return true;
  }

  bool queueUnit({
    required int teamId,
    required String archetype,
    EntityId? preferredFacility,
  }) {
    final blueprint = SwiftRtsCatalog.unitOrNull(archetype);
    if (blueprint == null) return false;
    if (unitsForTeam(teamId).length >= unitCap) {
      if (teamId == playerTeamId) {
        status = 'Unit cap reached: $unitCap active units.';
      }
      return false;
    }
    if (!prerequisitesMet(teamId, blueprint.prerequisites)) {
      status = '${blueprint.label} prerequisites are not met.';
      return false;
    }

    final facility = _resolveProducer(
      teamId: teamId,
      producer: blueprint.producer,
      preferredFacility: preferredFacility,
    );
    if (facility == null) {
      if (teamId == playerTeamId) {
        status = 'No ${blueprint.producer} is available.';
      }
      return false;
    }

    final queue = facilityQueue(facility);
    if (queue.snapshot.count >= queue.limit) {
      if (teamId == playerTeamId) {
        status = '${blueprint.label} queue is full.';
      }
      return false;
    }
    if (!_spend(teamId, blueprint.prototypeCost)) {
      if (teamId == playerTeamId) {
        status = 'Insufficient credits for ${blueprint.label}.';
      }
      return false;
    }

    final added = queue.enqueue(
      RuntimeOrder(
        archetype: blueprint.id,
        label: blueprint.label,
        cost: blueprint.prototypeCost,
        buildTicks: blueprint.prototypeBuildTicks,
      ),
    );
    if (!added) {
      wallet(teamId).credit(blueprint.prototypeCost);
      return false;
    }

    replay.record(
      ReplayEvent(
        tick: world.tick,
        type: 'queue_unit',
        payload: <String, Object?>{
          'team': teamId,
          'facility': facility.value,
          'archetype': blueprint.id,
        },
      ),
    );
    if (teamId == playerTeamId) {
      status =
          '${blueprint.label} queued at ${world.buildings[facility]?.archetype} #${facility.value}.';
    }
    return true;
  }

  RuntimeOrder? cancelLastFacilityOrder(EntityId facilityId) {
    final building = world.buildings[facilityId];
    final queue = _facilityQueues[facilityId];
    if (building == null || queue == null) return null;
    final order = queue.cancelLast();
    if (order != null) {
      wallet(building.teamId).credit(order.cost);
      status = '${order.label} cancelled and queued cost refunded.';
    }
    return order;
  }

  bool makePrimary(EntityId buildingId) {
    final building = world.buildings[buildingId];
    if (building == null || !building.alive) return false;
    final changed = primaryFacilities.makePrimary(
      world: world,
      teamId: building.teamId,
      archetype: building.archetype,
      buildingId: buildingId,
    );
    if (changed) {
      status = '${building.archetype} #${buildingId.value} is now Primary.';
    }
    return changed;
  }

  void setRallyPoint(EntityId buildingId, Vec2 point) {
    final building = world.buildings[buildingId];
    if (building == null || !building.alive) return;
    rallyPoints[buildingId] = point;
    status = 'Rally point set for ${building.archetype} #${buildingId.value}.';
  }

  bool manualRepair(EntityId buildingId) {
    final building = world.buildings[buildingId];
    if (building == null ||
        !building.alive ||
        building.teamId != playerTeamId) {
      return false;
    }

    if (manualRepairEnabled.remove(buildingId)) {
      status = 'Paid manual repair stopped.';
      return true;
    }

    final engineersRepairing = _engineerTargets.entries.any((entry) =>
        entry.value == buildingId &&
        _engineerModes[entry.key] == EngineerTaskMode.repair &&
        world.units[entry.key]?.alive == true);
    if (engineersRepairing) {
      status = 'Engineer repair is active; repair modes do not stack.';
      return false;
    }

    if (building.health >= building.maxHealth) {
      status = 'Building is already at full health.';
      return false;
    }

    manualRepairEnabled.add(buildingId);
    status = 'Paid manual repair enabled (prototype pricing).';
    return true;
  }

  void assignEngineerTask({
    required EntityId engineerId,
    required EntityId buildingId,
    required EngineerTaskMode mode,
  }) {
    final engineer = world.units[engineerId];
    final building = world.buildings[buildingId];
    if (engineer == null ||
        building == null ||
        !engineer.alive ||
        !building.alive ||
        engineer.archetype != 'engineer') {
      return;
    }

    if (mode == EngineerTaskMode.repair) {
      manualRepairEnabled.remove(buildingId);
    }
    _engineerTargets[engineerId] = buildingId;
    _engineerModes[engineerId] = mode;
    engineer.moveTarget = _interactionPoint(
      building: building,
      from: engineer.position,
    );
    status = 'Engineer assigned to ${mode.name}.';
  }

  void assignSpyTarget({
    required EntityId spyId,
    required EntityId buildingId,
  }) {
    final spy = world.units[spyId];
    final building = world.buildings[buildingId];
    if (spy == null ||
        building == null ||
        !spy.alive ||
        !building.alive ||
        spy.archetype != 'spy' ||
        spy.teamId == building.teamId) {
      return;
    }
    _spyTargets[spyId] = buildingId;
    spy.moveTarget = _interactionPoint(
      building: building,
      from: spy.position,
    );
    status = 'Spy moving to infiltrate ${building.archetype}.';
  }

  bool purgeCompromisedBuilding(EntityId buildingId) {
    final building = world.buildings[buildingId];
    final compromise = compromisedBuildings[buildingId];
    if (building == null ||
        compromise == null ||
        !building.alive ||
        building.teamId != playerTeamId) {
      return false;
    }

    final blueprint = SwiftRtsCatalog.buildingOrNull(building.archetype);
    final faceValue = blueprint?.prototypeCost ?? 0;
    final refund = stolenTech.removeBySellingSource(
      teamId: compromise.infiltratingTeamId,
      sourceFaceValue: faceValue,
    );
    wallet(building.teamId).credit(refund);
    world.destroy(buildingId);
    _facilityQueues.remove(buildingId);
    rallyPoints.remove(buildingId);
    compromisedBuildings.remove(buildingId);
    selection.replaceWith(
      selection.selected.where((id) => id != buildingId),
    );
    status =
        'Compromised building purged for locked 10% face-value refund: $refund.';
    return true;
  }

  bool ordinarySellAvailable(EntityId buildingId) {
    // Final ordinary sell percentage is intentionally not invented.
    return false;
  }

  bool beginSpecialPowerTargeting() {
    final state = specialPowers[playerTeamId];
    if (state == null || !state.ready) return false;
    specialPowerTargeting = true;
    status = 'Special Power Slot 1 ready: choose a battlefield target.';
    return true;
  }

  bool firePrototypeSpecialPower(Vec2 target) {
    final state = specialPowers[playerTeamId];
    if (!specialPowerTargeting ||
        state == null ||
        !state.ready ||
        !mapRuntime.contains(target)) {
      return false;
    }

    // Effect is intentionally generic/prototype: a temporary power disruption.
    for (final building in world.buildings.values) {
      if (!building.alive || building.teamId == playerTeamId) continue;
      if (building.position.distanceTo(target) <= 120) {
        _powerOutageUntilTick[building.id] = world.tick + 300;
        building.powered = false;
      }
    }

    state.fire();
    specialPowerTargeting = false;
    replay.record(
      ReplayEvent(
        tick: world.tick,
        type: 'prototype_special_power',
        payload: <String, Object?>{'target': target.toJson()},
      ),
    );
    status = 'Prototype special power discharged.';
    return true;
  }

  void toggleSelection(EntityId id) {
    final unit = world.units[id];
    final building = world.buildings[id];
    final teamId = unit?.teamId ?? building?.teamId;
    if (teamId != playerTeamId) return;
    selection.toggle(id);
  }

  void selectBox({
    required Vec2 a,
    required Vec2 b,
  }) {
    final left = math.min(a.x, b.x);
    final right = math.max(a.x, b.x);
    final top = math.min(a.y, b.y);
    final bottom = math.max(a.y, b.y);

    final ids = <EntityId>[
      for (final unit in world.units.values)
        if (unit.alive &&
            unit.teamId == playerTeamId &&
            unit.position.x >= left &&
            unit.position.x <= right &&
            unit.position.y >= top &&
            unit.position.y <= bottom)
          unit.id,
    ]..sort();

    selection.replaceWith(ids);
    status = '${ids.length} unit(s) selected.';
  }

  void clearSelection() {
    selection.clear();
  }

  void commandMove(Vec2 destination) {
    final units = selection.selected
        .where((id) {
          final unit = world.units[id];
          return unit != null && unit.alive && unit.teamId == playerTeamId;
        })
        .toList()
      ..sort();
    if (units.isEmpty) return;

    final positions = formation.plan(
      units: units,
      destination: destination,
      spacing: 38,
    );
    for (final entry in positions.entries) {
      moveOrders.apply(
        world,
        MoveCommand(
          tick: world.tick,
          playerId: playerTeamId,
          units: <EntityId>[entry.key],
          destination: entry.value,
        ),
      );
    }
    replay.record(
      ReplayEvent(
        tick: world.tick,
        type: 'move',
        payload: <String, Object?>{
          'units': units.map((id) => id.value).toList(),
          'destination': destination.toJson(),
        },
      ),
    );
    status = 'Move order issued to ${units.length} unit(s).';
  }

  void stopSelected() {
    var stopped = 0;
    for (final id in selection.selected) {
      final unit = world.units[id];
      if (unit == null ||
          !unit.alive ||
          unit.teamId != playerTeamId) {
        continue;
      }
      unit.moveTarget = null;
      unit.attackTarget = null;
      stopped += 1;
    }
    status = 'Stopped $stopped unit(s).';
  }

  void commandAttack(EntityId targetId) {
    final attackers = selection.selected
        .where((id) {
          final unit = world.units[id];
          return unit != null && unit.alive && unit.teamId == playerTeamId;
        })
        .toList()
      ..sort();

    if (attackers.isEmpty) return;
    attackOrders.apply(
      world,
      AttackCommand(
        tick: world.tick,
        playerId: playerTeamId,
        attackers: attackers,
        target: targetId,
      ),
    );
    replay.record(
      ReplayEvent(
        tick: world.tick,
        type: 'attack',
        payload: <String, Object?>{
          'attackers': attackers.map((id) => id.value).toList(),
          'target': targetId.value,
        },
      ),
    );
    status = 'Attack order issued.';
  }

  EntityId? hitTest(Vec2 position, {double radius = 30}) {
    final friendlyUnits = world.units.values
        .where((unit) => unit.alive && unit.teamId == playerTeamId)
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    for (final unit in friendlyUnits.reversed) {
      if (unit.position.distanceTo(position) <= radius) return unit.id;
    }

    final visibleEnemies = world.units.values
        .where((unit) =>
            unit.alive &&
            unit.teamId != playerTeamId &&
            visibility.isVisible(playerTeamId, unit.position))
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    for (final unit in visibleEnemies.reversed) {
      if (unit.position.distanceTo(position) <= radius) return unit.id;
    }

    final buildings = world.buildings.values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    for (final building in buildings.reversed) {
      if (!building.alive) continue;
      if (building.teamId != playerTeamId &&
          !visibility.isVisible(playerTeamId, building.position)) {
        continue;
      }
      final blueprint = SwiftRtsCatalog.buildingOrNull(building.archetype);
      final halfW =
          (blueprint?.footprintCols ?? 2) * SwiftRtsCatalog.cellSize / 2;
      final halfH =
          (blueprint?.footprintRows ?? 2) * SwiftRtsCatalog.cellSize / 2;
      if ((position.x - building.position.x).abs() <= halfW &&
          (position.y - building.position.y).abs() <= halfH) {
        return building.id;
      }
    }
    return null;
  }

  void handleTap(Vec2 worldPosition) {
    if (specialPowerTargeting) {
      firePrototypeSpecialPower(worldPosition);
      return;
    }

    final structure = structureQueue(playerTeamId).readyOrder;
    if (structure != null) {
      placeReadyStructure(
        teamId: playerTeamId,
        position: worldPosition,
      );
      return;
    }

    final hit = hitTest(worldPosition);
    if (hit != null) {
      final unit = world.units[hit];
      final building = world.buildings[hit];
      final teamId = unit?.teamId ?? building?.teamId;

      if (teamId == playerTeamId) {
        toggleSelection(hit);
        return;
      }

      final selectedSpies = selection.selected
          .where((id) => world.units[id]?.archetype == 'spy')
          .toList()
        ..sort();
      if (building != null && selectedSpies.isNotEmpty) {
        assignSpyTarget(
          spyId: selectedSpies.first,
          buildingId: hit,
        );
        return;
      }

      final selectedEngineers = selection.selected
          .where((id) => world.units[id]?.archetype == 'engineer')
          .toList()
        ..sort();
      if (building != null && selectedEngineers.isNotEmpty) {
        for (final engineer in selectedEngineers.take(3)) {
          assignEngineerTask(
            engineerId: engineer,
            buildingId: hit,
            mode: engineerMode,
          );
        }
        return;
      }

      commandAttack(hit);
      return;
    }

    commandMove(worldPosition);
  }

  void setEngineerMode(EngineerTaskMode mode) {
    engineerMode = mode;
    status = 'Engineer mode: ${mode.name}.';
  }

  void assignEngineersToFriendlyBuilding(EntityId buildingId) {
    final building = world.buildings[buildingId];
    if (building == null || building.teamId != playerTeamId) return;
    final engineers = selection.selected
        .where((id) => world.units[id]?.archetype == 'engineer')
        .toList()
      ..sort();
    for (final engineer in engineers.take(3)) {
      assignEngineerTask(
        engineerId: engineer,
        buildingId: buildingId,
        mode: EngineerTaskMode.repair,
      );
    }
  }

  bool isCompromised(EntityId buildingId) {
    return compromisedBuildings.containsKey(buildingId);
  }

  bool _spend(int teamId, int amount) {
    final ok = wallet(teamId).spend(amount);
    if (ok) {
      storage(teamId).withdraw(amount);
    }
    return ok;
  }

  EntityId? _resolveProducer({
    required int teamId,
    required String producer,
    EntityId? preferredFacility,
  }) {
    if (preferredFacility != null) {
      final building = world.buildings[preferredFacility];
      if (building != null &&
          building.alive &&
          building.teamId == teamId &&
          building.archetype == producer) {
        return preferredFacility;
      }
    }

    if (PrimaryFacilityRegistry.supports(producer)) {
      return primaryFacilities.primaryFor(
        world: world,
        teamId: teamId,
        archetype: producer,
      );
    }

    final facilities = buildingsForTeam(teamId, archetype: producer);
    return facilities.isEmpty ? null : facilities.first.id;
  }

  bool _placementClear(
    Vec2 position,
    BuildingBlueprint blueprint,
  ) {
    final halfW =
        blueprint.footprintCols * SwiftRtsCatalog.cellSize / 2;
    final halfH =
        blueprint.footprintRows * SwiftRtsCatalog.cellSize / 2;

    if (position.x - halfW < 0 ||
        position.y - halfH < 0 ||
        position.x + halfW > mapSpec.width ||
        position.y + halfH > mapSpec.height) {
      return false;
    }

    for (final building in world.buildings.values) {
      if (!building.alive) continue;
      final other =
          SwiftRtsCatalog.buildingOrNull(building.archetype);
      final otherHalfW =
          (other?.footprintCols ?? 2) * SwiftRtsCatalog.cellSize / 2;
      final otherHalfH =
          (other?.footprintRows ?? 2) * SwiftRtsCatalog.cellSize / 2;
      if ((position.x - building.position.x).abs() <
              halfW + otherHalfW + 8 &&
          (position.y - building.position.y).abs() <
              halfH + otherHalfH + 8) {
        return false;
      }
    }
    return true;
  }

  void _recalculatePower() {
    _powerOutageUntilTick.removeWhere((id, until) =>
        world.buildings[id]?.alive != true || until <= world.tick);

    for (final teamId in <int>[playerTeamId, enemyTeamId]) {
      var produced = 0;
      var demand = 0;
      for (final building in world.buildings.values) {
        if (!building.alive || building.teamId != teamId) continue;
        final blueprint =
            SwiftRtsCatalog.buildingOrNull(building.archetype);
        if (blueprint == null) continue;
        produced += blueprint.powerProvided;
        demand += blueprint.powerDemand;
      }

      final grid = power(teamId)
        ..produced = produced
        ..demand = demand;
      final lowPower = grid.lowPower;

      for (final building in world.buildings.values) {
        if (!building.alive || building.teamId != teamId) continue;
        final blueprint =
            SwiftRtsCatalog.buildingOrNull(building.archetype);
        final forcedOutage =
            (_powerOutageUntilTick[building.id] ?? 0) > world.tick;
        building.powered = !forcedOutage &&
            (blueprint?.powerProvided != 0 || !lowPower);
      }

      final team = world.team(teamId);
      team.powerProduced = produced;
      team.powerUsed = demand;
    }
  }

  void _recalculateStorageCapacity() {
    for (final teamId in <int>[playerTeamId, enemyTeamId]) {
      var capacity = 0;
      for (final building in world.buildings.values) {
        if (!building.alive || building.teamId != teamId) continue;
        final blueprint =
            SwiftRtsCatalog.buildingOrNull(building.archetype);
        capacity += blueprint?.storageCapacity ?? 0;
      }

      final silo = storage(teamId);
      silo.capacity = capacity;
      if (silo.stored > capacity) {
        silo.stored = capacity;
      }
      world.team(teamId).storageCapacity = capacity;
    }
  }

  void _tickStructureQueues() {
    for (final teamId in <int>[playerTeamId, enemyTeamId]) {
      final queue = structureQueue(teamId);
      final speed = PowerPenalties(power(teamId)).productionSpeed;
      queue.tick(speed);

      if (teamId == playerTeamId && queue.readyOrder != null) {
        status =
            '${queue.readyOrder!.label} READY — tap battlefield to place.';
      }
    }
  }

  void _tickFacilityQueues() {
    final ids = _facilityQueues.keys.toList()..sort();
    for (final buildingId in ids) {
      final building = world.buildings[buildingId];
      final queue = _facilityQueues[buildingId];
      if (building == null || !building.alive || queue == null) {
        _facilityQueues.remove(buildingId);
        continue;
      }

      final speed =
          PowerPenalties(power(building.teamId)).productionSpeed;
      queue.tick(speed);

      final ready = queue.readyOrder;
      if (ready == null) continue;

      final blueprint = SwiftRtsCatalog.unitOrNull(ready.archetype);
      if (blueprint == null) {
        queue.acceptReady();
        continue;
      }

      final spawn = _findSafeSpawn(buildingId);
      if (spawn == null) {
        if (building.teamId == playerTeamId) {
          status = '${ready.label} READY — exit blocked.';
        }
        continue;
      }

      final unit = _spawnUnit(
        teamId: building.teamId,
        archetype: ready.archetype,
        position: spawn,
      );
      queue.acceptReady();

      final rally = rallyPoints[buildingId];
      if (rally != null) {
        world.units[unit]?.moveTarget = rally;
      } else {
        world.units[unit]?.moveTarget =
            Vec2(spawn.x + 70, spawn.y);
      }

      if (building.teamId == playerTeamId) {
        status =
            '${blueprint.label} completed at ${building.archetype} #${buildingId.value}.';
      }
    }
  }

  Vec2? _findSafeSpawn(EntityId buildingId) {
    final building = world.buildings[buildingId];
    if (building == null) return null;
    final blueprint =
        SwiftRtsCatalog.buildingOrNull(building.archetype);
    final halfW =
        (blueprint?.footprintCols ?? 2) * SwiftRtsCatalog.cellSize / 2;
    final halfH =
        (blueprint?.footprintRows ?? 2) * SwiftRtsCatalog.cellSize / 2;

    final candidates = <Vec2>[
      Vec2(building.position.x + halfW + 42, building.position.y),
      Vec2(building.position.x + halfW + 42, building.position.y - 42),
      Vec2(building.position.x + halfW + 42, building.position.y + 42),
      Vec2(building.position.x - halfW - 42, building.position.y),
      Vec2(building.position.x, building.position.y - halfH - 42),
      Vec2(building.position.x, building.position.y + halfH + 42),
      Vec2(building.position.x + halfW + 84, building.position.y - 42),
      Vec2(building.position.x + halfW + 84, building.position.y + 42),
    ];

    for (final candidate in candidates) {
      if (_unitPositionClear(null, candidate, spacing: 34)) {
        return candidate;
      }
    }
    return null;
  }

  bool _unitPositionClear(
    EntityId? movingId,
    Vec2 candidate, {
    double spacing = 28,
  }) {
    if (!mapRuntime.contains(candidate) || mapRuntime.isBlocked(candidate)) {
      return false;
    }

    for (final unit in world.units.values) {
      if (!unit.alive || unit.id == movingId) continue;
      if (unit.position.distanceTo(candidate) < spacing) return false;
    }

    for (final building in world.buildings.values) {
      if (!building.alive) continue;
      final blueprint =
          SwiftRtsCatalog.buildingOrNull(building.archetype);
      final halfW =
          (blueprint?.footprintCols ?? 2) * SwiftRtsCatalog.cellSize / 2;
      final halfH =
          (blueprint?.footprintRows ?? 2) * SwiftRtsCatalog.cellSize / 2;
      if ((candidate.x - building.position.x).abs() <= halfW + 14 &&
          (candidate.y - building.position.y).abs() <= halfH + 14) {
        return false;
      }
    }

    return true;
  }

  void _tickMovement(double dt) {
    final units = world.units.values.where((unit) => unit.alive).toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    for (final unit in units) {
      final target = unit.moveTarget;
      if (target == null) continue;

      final blueprint = SwiftRtsCatalog.unitOrNull(unit.archetype);
      final speed = blueprint?.speed ?? 60;
      final delta = target - unit.position;
      final distance = delta.length;
      if (distance <= 3) {
        unit.position = target;
        unit.moveTarget = null;
        continue;
      }

      final step = math.min(distance, speed * dt);
      final candidate =
          unit.position + delta.normalized() * step.toDouble();
      if (_unitPositionClear(unit.id, candidate)) {
        unit.position = candidate;
        continue;
      }

      final xOnly = Vec2(candidate.x, unit.position.y);
      if (_unitPositionClear(unit.id, xOnly)) {
        unit.position = xOnly;
        continue;
      }

      final yOnly = Vec2(unit.position.x, candidate.y);
      if (_unitPositionClear(unit.id, yOnly)) {
        unit.position = yOnly;
      }
    }
  }

  void _tickCombat() {
    final units = world.units.values.where((unit) => unit.alive).toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    for (final unit in units) {
      final blueprint = SwiftRtsCatalog.unitOrNull(unit.archetype);
      if (blueprint == null || blueprint.attackDamage <= 0) continue;

      var targetId = unit.attackTarget;
      if (targetId == null && world.tick % 30 == 0) {
        targetId = targets.nearestEnemy(
          world: world,
          teamId: unit.teamId,
          origin: unit.position,
          range: blueprint.attackRange * 1.35,
        );
        unit.attackTarget = targetId;
      }
      if (targetId == null) continue;

      final targetPosition = world.units[targetId]?.position ??
          world.buildings[targetId]?.position;
      if (targetPosition == null) {
        unit.attackTarget = null;
        continue;
      }

      final distance = unit.position.distanceTo(targetPosition);
      if (distance > blueprint.attackRange) {
        unit.moveTarget = targetPosition;
        continue;
      }

      unit.moveTarget = null;
      final last = _lastAttackTick[unit.id] ?? -999999;
      if (world.tick - last < blueprint.attackCooldownTicks) continue;
      _lastAttackTick[unit.id] = world.tick;

      combat.applyDamage(
        world: world,
        target: targetId,
        packet: DamagePacket(
          amount: blueprint.attackDamage,
          type: blueprint.id == 'tank'
              ? DamageType.explosive
              : DamageType.kinetic,
        ),
      );

      if (world.entities[targetId]?.alive != true) {
        unit.attackTarget = null;
      }
    }
  }

  void _tickManualRepairs() {
    if (world.tick % SwiftRtsCatalog.prototypeManualRepairIntervalTicks != 0) {
      return;
    }

    final ids = manualRepairEnabled.toList()..sort();
    for (final buildingId in ids) {
      final building = world.buildings[buildingId];
      if (building == null ||
          !building.alive ||
          building.teamId != playerTeamId ||
          building.health >= building.maxHealth) {
        manualRepairEnabled.remove(buildingId);
        continue;
      }

      final cost = SwiftRtsCatalog.prototypeManualRepairCreditsPerStep;
      if (!_spend(playerTeamId, cost)) {
        manualRepairEnabled.remove(buildingId);
        status = 'Paid repair stopped: insufficient credits.';
        continue;
      }

      repair.repairBuilding(
        world: world,
        buildingId: buildingId,
        engineerIds: const <EntityId>[],
        mode: RepairMode.manual,
        lowPower: false,
        manualPoints: SwiftRtsCatalog.prototypeManualRepairPointsPerStep,
      );
      if (building.health >= building.maxHealth) {
        manualRepairEnabled.remove(buildingId);
        status = 'Building repair complete.';
      }
    }
  }

  void _tickLowPowerBreakdown() {
    if (world.tick % SwiftRtsCatalog.prototypeLowPowerBreakdownIntervalTicks != 0) {
      return;
    }

    for (final teamId in <int>[playerTeamId, enemyTeamId]) {
      if (!power(teamId).lowPower) continue;

      final ids = buildingsForTeam(teamId)
          .where((building) => building.archetype != 'power_plant')
          .map((building) => building.id)
          .toList()
        ..sort();

      for (final id in ids) {
        combat.applyDamage(
          world: world,
          target: id,
          packet: const DamagePacket(
            amount: SwiftRtsCatalog.prototypeLowPowerBreakdownDamage,
            type: DamageType.sabotage,
          ),
        );
      }
    }
  }

  void _applyIntegrityFinding(IntegrityFinding finding) {
    switch (finding.response) {
      case IntegrityResponse.none:
        return;
      case IntegrityResponse.markSuspected:
        flaggedCheaterTeams.add(finding.teamId);
        status = 'Integrity warning: Team ${finding.teamId} marked suspected.';
        return;
      case IntegrityResponse.diminishAssets:
        flaggedCheaterTeams.add(finding.teamId);
        final factor = SwiftRtsCatalog.prototypeIntegrityDiminishFactor;
        for (final unit in unitsForTeam(finding.teamId)) {
          unit.health =
              math.max(1, (unit.health * factor).floor()).toInt();
        }
        for (final building in buildingsForTeam(finding.teamId)) {
          building.health =
              math.max(1, (building.health * factor).floor()).toInt();
        }
        status =
            'Integrity enforcement: Team ${finding.teamId} assets diminished.';
        return;
      case IntegrityResponse.eliminate:
        flaggedCheaterTeams.add(finding.teamId);
        final unitIds = unitsForTeam(finding.teamId).map((u) => u.id).toList();
        final buildingIds =
            buildingsForTeam(finding.teamId).map((b) => b.id).toList();
        for (final id in <EntityId>[...unitIds, ...buildingIds]) {
          world.destroy(id);
        }
        status = 'Integrity enforcement: Team ${finding.teamId} eliminated.';
        return;
    }
  }

  void _tickHarvesters() {
    final ids = harvesters.keys.toList()..sort();
    for (final unitId in ids) {
      final unit = world.units[unitId];
      final harvester = harvesters[unitId];
      if (unit == null || !unit.alive || harvester == null) {
        harvesters.remove(unitId);
        continue;
      }

      if (!harvester.full) {
        final field = _nearestOre(unit.position);
        if (field != null) {
          if (unit.position.distanceTo(field.position) > 34) {
            unit.moveTarget = field.position;
          } else if (world.tick % 5 == 0) {
            final available = field.harvest(5);
            harvester.collect(available);
          }
          continue;
        }
      }

      final refinery = _nearestBuilding(
        teamId: unit.teamId,
        archetype: 'refinery',
        position: unit.position,
      );
      if (refinery == null) continue;

      if (unit.position.distanceTo(refinery.position) > 52) {
        unit.moveTarget = refinery.position;
        continue;
      }

      final silo = storage(unit.teamId);
      final room = math.max(0, silo.capacity - silo.stored);
      if (room <= 0) {
        if (unit.teamId == playerTeamId) {
          status = 'Ore storage full — construct a Silo.';
        }
        continue;
      }

      final accepted = math.min(room, harvester.cargo).toInt();
      if (accepted <= 0) continue;
      harvester.cargo -= accepted;
      silo.deposit(accepted);
      wallet(unit.teamId).credit(accepted);
      if (unit.teamId == playerTeamId) {
        status = 'Harvester delivered +$accepted credits.';
      }
    }
  }

  OreField? _nearestOre(Vec2 position) {
    OreField? best;
    var bestDistance = double.infinity;
    for (final field in oreFields) {
      if (field.depleted) continue;
      final distance = field.position.distanceTo(position);
      if (distance < bestDistance) {
        best = field;
        bestDistance = distance;
      }
    }
    return best;
  }

  BuildingState? _nearestBuilding({
    required int teamId,
    required String archetype,
    required Vec2 position,
  }) {
    BuildingState? best;
    var bestDistance = double.infinity;
    for (final building in world.buildings.values) {
      if (!building.alive ||
          building.teamId != teamId ||
          building.archetype != archetype) {
        continue;
      }
      final distance = building.position.distanceTo(position);
      if (distance < bestDistance) {
        best = building;
        bestDistance = distance;
      }
    }
    return best;
  }

  double _interactionRange(BuildingState building) {
    final blueprint =
        SwiftRtsCatalog.buildingOrNull(building.archetype);
    final halfW =
        (blueprint?.footprintCols ?? 2) * SwiftRtsCatalog.cellSize / 2;
    final halfH =
        (blueprint?.footprintRows ?? 2) * SwiftRtsCatalog.cellSize / 2;
    return (math.max(halfW, halfH) + 38).toDouble();
  }

  Vec2 _interactionPoint({
    required BuildingState building,
    required Vec2 from,
  }) {
    final delta = from - building.position;
    final direction = delta.length <= 0.001
        ? const Vec2(1, 0)
        : delta.normalized();
    return building.position +
        direction * _interactionRange(building);
  }

  void _tickPendingInfiltration() {
    final spyIds = _spyTargets.keys.toList()..sort();
    for (final spyId in spyIds) {
      final spy = world.units[spyId];
      final buildingId = _spyTargets[spyId];
      final building = buildingId == null ? null : world.buildings[buildingId];
      if (spy == null ||
          building == null ||
          !spy.alive ||
          !building.alive) {
        _spyTargets.remove(spyId);
        continue;
      }

      if (spy.position.distanceTo(building.position) >
          _interactionRange(building)) {
        continue;
      }
      final techId = building.archetype;
      stolenTech.grantStolen(spy.teamId, <String>[techId]);
      compromisedBuildings[building.id] = CompromiseRecord(
        infiltratingTeamId: spy.teamId,
        stolenTechId: techId,
      );
      world.destroy(spyId);
      _spyTargets.remove(spyId);
      if (spy.teamId == playerTeamId) {
        status = 'Spy stole $techId technology.';
      }
    }

    final engineerIds = _engineerTargets.keys.toList()..sort();
    final repairGroups = <EntityId, List<EntityId>>{};

    for (final engineerId in engineerIds) {
      final engineer = world.units[engineerId];
      final buildingId = _engineerTargets[engineerId];
      final building =
          buildingId == null ? null : world.buildings[buildingId];
      final mode = _engineerModes[engineerId];
      if (engineer == null ||
          building == null ||
          mode == null ||
          !engineer.alive ||
          !building.alive) {
        _engineerTargets.remove(engineerId);
        _engineerModes.remove(engineerId);
        continue;
      }

      if (engineer.position.distanceTo(building.position) >
          _interactionRange(building)) {
        continue;
      }

      if (mode == EngineerTaskMode.repair) {
        if (engineer.teamId == building.teamId) {
          repairGroups
              .putIfAbsent(building.id, () => <EntityId>[])
              .add(engineer.id);
        }
        continue;
      }

      if (engineer.teamId == building.teamId || world.tick % 30 != 0) {
        continue;
      }

      final result = infiltration.apply(
        world: world,
        engineerId: engineer.id,
        buildingId: building.id,
        mode: mode == EngineerTaskMode.capture
            ? InfiltrationMode.capture
            : InfiltrationMode.sabotage,
        amount: 25,
      );

      if (!result.completed) continue;

      if (mode == EngineerTaskMode.capture) {
        final position = building.position;
        final archetype = building.archetype;
        final health = math.max(1, building.health).toInt();
        world.destroy(building.id);
        _spawnBuilding(
          teamId: engineer.teamId,
          archetype: archetype,
          position: position,
          health: health,
        );
      } else {
        _powerOutageUntilTick[building.id] = world.tick + 600;
        building.powered = false;
      }
      world.destroy(engineer.id);
      _engineerTargets.remove(engineerId);
      _engineerModes.remove(engineerId);
    }

    if (world.tick % 30 == 0) {
      for (final entry in repairGroups.entries) {
        final building = world.buildings[entry.key];
        if (building == null || !building.alive) continue;
        final lowPower = power(building.teamId).lowPower;
        repair.repairBuilding(
          world: world,
          buildingId: entry.key,
          engineerIds: entry.value,
          mode: RepairMode.engineers,
          lowPower: lowPower,
        );
      }
    }
  }

  void _tickSpecialPowers() {
    for (final teamId in <int>[playerTeamId, enemyTeamId]) {
      final state = specialPowers[teamId];
      if (state == null) continue;
      final unlocked = prerequisitesMet(
        teamId,
        SwiftRtsCatalog.prototypeSpecialPower.prerequisites,
      );
      state.tick(
        powered: unlocked &&
            PowerPenalties(power(teamId)).superweaponsEnabled,
      );
    }
  }

  void _tickAi() {
    if (!enemyAi.shouldThink(world.tick)) return;

    final perception = AiPerception.fromWorld(world, enemyTeamId);
    final combatDecision = aiCombat.decide(perception);
    if (combatDecision.target != null &&
        combatDecision.attackers.isNotEmpty) {
      attackOrders.apply(
        world,
        AttackCommand(
          tick: world.tick,
          playerId: enemyTeamId,
          attackers: combatDecision.attackers,
          target: combatDecision.target!,
        ),
      );
    }

    final decision = aiEconomy.decide(
      funds: wallet(enemyTeamId).balance,
      hasRefinery: ownsBuilding(enemyTeamId, 'refinery'),
      lowPower: power(enemyTeamId).lowPower,
      harvesters:
          unitsForTeam(enemyTeamId, archetype: 'harvester').length,
    );

    if (decision.action == 'build_power') {
      queueStructure(enemyTeamId, 'power_plant');
    } else if (decision.action == 'build_refinery') {
      queueStructure(enemyTeamId, 'refinery');
    } else if (decision.action == 'produce_harvester') {
      queueUnit(
        teamId: enemyTeamId,
        archetype: 'harvester',
      );
    } else if (world.tick % 600 == 0 &&
        ownsBuilding(enemyTeamId, 'war_factory') &&
        unitsForTeam(enemyTeamId, archetype: 'tank').length < 8) {
      queueUnit(
        teamId: enemyTeamId,
        archetype: 'tank',
      );
    }

    final ready = structureQueue(enemyTeamId).readyOrder;
    if (ready != null) {
      final anchor =
          buildingsForTeam(enemyTeamId, archetype: 'hq').firstOrNull;
      if (anchor != null) {
        final offsets = <Vec2>[
          const Vec2(-120, 0),
          const Vec2(-120, -100),
          const Vec2(0, -120),
          const Vec2(-220, -80),
          const Vec2(-220, 40),
        ];
        for (final offset in offsets) {
          if (placeReadyStructure(
            teamId: enemyTeamId,
            position: anchor.position + offset,
          )) {
            break;
          }
        }
      }
    }
  }

  void _tickStorm() {
    if (!matchRules.suddenDeathActive(world.tick) ||
        world.tick % 60 != 0) {
      return;
    }

    const center = Vec2(600, 400);
    final radius = stormRadius;

    final unitIds = world.units.values
        .where((unit) =>
            unit.alive && unit.position.distanceTo(center) > radius)
        .map((unit) => unit.id)
        .toList()
      ..sort();
    for (final id in unitIds) {
      combat.applyDamage(
        world: world,
        target: id,
        packet: const DamagePacket(
          amount: 3,
          type: DamageType.energy,
        ),
      );
    }

    final buildingIds = world.buildings.values
        .where((building) =>
            building.alive &&
            building.position.distanceTo(center) > radius)
        .map((building) => building.id)
        .toList()
      ..sort();
    for (final id in buildingIds) {
      combat.applyDamage(
        world: world,
        target: id,
        packet: const DamagePacket(
          amount: 2,
          type: DamageType.energy,
        ),
      );
    }
  }
}

extension _IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    for (final value in this) {
      return value;
    }
    return null;
  }
}

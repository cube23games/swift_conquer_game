import '../../sc_master/world/unit_state.dart';

enum RtsProductionLane {
  structures,
  infantry,
  vehicles,
  air,
  naval,
  operations,
}

final class BuildingBlueprint {
  final String id;
  final String label;
  final int prototypeCost;
  final int prototypeBuildTicks;
  final int powerProvided;
  final int powerDemand;
  final int storageCapacity;
  final int footprintCols;
  final int footprintRows;
  final Set<String> prerequisites;
  final bool productionFacility;
  final RtsProductionLane lane;
  final bool canonicalDataPending;

  const BuildingBlueprint({
    required this.id,
    required this.label,
    required this.prototypeCost,
    required this.prototypeBuildTicks,
    this.powerProvided = 0,
    this.powerDemand = 0,
    this.storageCapacity = 0,
    this.footprintCols = 2,
    this.footprintRows = 2,
    this.prerequisites = const {},
    this.productionFacility = false,
    this.lane = RtsProductionLane.structures,
    this.canonicalDataPending = true,
  });
}

final class UnitBlueprint {
  final String id;
  final String label;
  final int prototypeCost;
  final int prototypeBuildTicks;
  final int health;
  final double speed;
  final double attackRange;
  final int attackDamage;
  final int attackCooldownTicks;
  final String producer;
  final Set<String> prerequisites;
  final Set<String> roles;
  final UnitDomain domain;
  final RtsProductionLane lane;
  final bool canonicalDataPending;

  const UnitBlueprint({
    required this.id,
    required this.label,
    required this.prototypeCost,
    required this.prototypeBuildTicks,
    required this.health,
    required this.speed,
    required this.attackRange,
    required this.attackDamage,
    required this.attackCooldownTicks,
    required this.producer,
    this.prerequisites = const {},
    this.roles = const {},
    this.domain = UnitDomain.land,
    required this.lane,
    this.canonicalDataPending = true,
  });
}

final class SpecialPowerBlueprint {
  final String id;
  final String label;
  final int prototypeChargeTicks;
  final Set<String> prerequisites;
  final bool canonicalDataPending;

  const SpecialPowerBlueprint({
    required this.id,
    required this.label,
    required this.prototypeChargeTicks,
    this.prerequisites = const {},
    this.canonicalDataPending = true,
  });
}

final class SwiftRtsCatalog {
  static const int prototypeStartingCredits = 15000;
  static const int prototypeQueueLimit = 5;
  static const double cellSize = 40;

  static const List<BuildingBlueprint> buildings = <BuildingBlueprint>[
    BuildingBlueprint(
      id: 'hq',
      label: 'Headquarters',
      prototypeCost: 0,
      prototypeBuildTicks: 0,
      footprintCols: 3,
      footprintRows: 3,
      canonicalDataPending: false,
    ),
    BuildingBlueprint(
      id: 'power_plant',
      label: 'Power Plant',
      prototypeCost: 800,
      prototypeBuildTicks: 300,
      powerProvided: 100,
      footprintCols: 2,
      footprintRows: 2,
      prerequisites: {'hq'},
    ),
    BuildingBlueprint(
      id: 'barracks',
      label: 'Barracks',
      prototypeCost: 600,
      prototypeBuildTicks: 360,
      powerDemand: 20,
      footprintCols: 2,
      footprintRows: 2,
      prerequisites: {'power_plant'},
      productionFacility: true,
      lane: RtsProductionLane.infantry,
    ),
    BuildingBlueprint(
      id: 'refinery',
      label: 'Refinery',
      prototypeCost: 1500,
      prototypeBuildTicks: 480,
      powerDemand: 30,
      storageCapacity: 2000,
      footprintCols: 3,
      footprintRows: 2,
      prerequisites: {'power_plant'},
      productionFacility: true,
      lane: RtsProductionLane.vehicles,
    ),
    BuildingBlueprint(
      id: 'war_factory',
      label: 'War Factory',
      prototypeCost: 1800,
      prototypeBuildTicks: 600,
      powerDemand: 40,
      footprintCols: 3,
      footprintRows: 3,
      prerequisites: {'refinery'},
      productionFacility: true,
      lane: RtsProductionLane.vehicles,
    ),
    BuildingBlueprint(
      id: 'silo',
      label: 'Silo',
      prototypeCost: 500,
      prototypeBuildTicks: 300,
      powerDemand: 5,
      storageCapacity: 3000,
      footprintCols: 1,
      footprintRows: 2,
      prerequisites: {'refinery'},
    ),
    BuildingBlueprint(
      id: 'advanced_tech',
      label: 'Advanced Tech Center',
      prototypeCost: 2200,
      prototypeBuildTicks: 900,
      powerDemand: 60,
      footprintCols: 3,
      footprintRows: 3,
      prerequisites: {'war_factory', 'power_plant'},
      lane: RtsProductionLane.operations,
    ),
    BuildingBlueprint(
      id: 'airfield',
      label: 'Airfield',
      prototypeCost: 1800,
      prototypeBuildTicks: 720,
      powerDemand: 45,
      footprintCols: 4,
      footprintRows: 3,
      prerequisites: {'war_factory'},
      productionFacility: true,
      lane: RtsProductionLane.air,
    ),
    BuildingBlueprint(
      id: 'naval_yard',
      label: 'Naval Yard',
      prototypeCost: 1800,
      prototypeBuildTicks: 720,
      powerDemand: 45,
      footprintCols: 4,
      footprintRows: 3,
      prerequisites: {'refinery'},
      productionFacility: true,
      lane: RtsProductionLane.naval,
    ),
  ];

  static const List<UnitBlueprint> units = <UnitBlueprint>[
    UnitBlueprint(
      id: 'infantry',
      label: 'Rifle Infantry',
      prototypeCost: 100,
      prototypeBuildTicks: 180,
      health: 30,
      speed: 70,
      attackRange: 110,
      attackDamage: 6,
      attackCooldownTicks: 30,
      producer: 'barracks',
      prerequisites: {'barracks'},
      roles: {'anti_personnel'},
      lane: RtsProductionLane.infantry,
      canonicalDataPending: false,
    ),
    UnitBlueprint(
      id: 'engineer',
      label: 'Engineer',
      prototypeCost: 250,
      prototypeBuildTicks: 300,
      health: 25,
      speed: 60,
      attackRange: 0,
      attackDamage: 0,
      attackCooldownTicks: 60,
      producer: 'barracks',
      prerequisites: {'barracks', 'refinery'},
      roles: {'repair', 'capture', 'sabotage'},
      lane: RtsProductionLane.infantry,
      canonicalDataPending: false,
    ),
    UnitBlueprint(
      id: 'spy',
      label: 'Spy',
      prototypeCost: 500,
      prototypeBuildTicks: 420,
      health: 20,
      speed: 72,
      attackRange: 0,
      attackDamage: 0,
      attackCooldownTicks: 60,
      producer: 'barracks',
      prerequisites: {'barracks', 'advanced_tech'},
      roles: {'infiltration', 'stolen_tech'},
      lane: RtsProductionLane.operations,
      canonicalDataPending: false,
    ),
    UnitBlueprint(
      id: 'harvester',
      label: 'Harvester',
      prototypeCost: 1200,
      prototypeBuildTicks: 480,
      health: 160,
      speed: 55,
      attackRange: 0,
      attackDamage: 0,
      attackCooldownTicks: 60,
      producer: 'refinery',
      prerequisites: {'refinery'},
      roles: {'economy'},
      lane: RtsProductionLane.vehicles,
      canonicalDataPending: false,
    ),
    UnitBlueprint(
      id: 'tank',
      label: 'Tank',
      prototypeCost: 900,
      prototypeBuildTicks: 360,
      health: 120,
      speed: 90,
      attackRange: 150,
      attackDamage: 18,
      attackCooldownTicks: 42,
      producer: 'war_factory',
      prerequisites: {'war_factory'},
      roles: {'armor'},
      lane: RtsProductionLane.vehicles,
      canonicalDataPending: false,
    ),
  ];

  static const SpecialPowerBlueprint prototypeSpecialPower =
      SpecialPowerBlueprint(
    id: 'special_power_slot_1',
    label: 'Special Power Slot 1',
    prototypeChargeTicks: 1800,
    prerequisites: {'advanced_tech'},
  );

  // Four legacy names were recovered. The final modern six-faction canon
  // was not recovered, so slots 5-6 and modern identities remain pending.
  static const Map<String, String?> factionSlots = <String, String?>{
    'slot1': 'Swift Dominion',
    'slot2': 'Iron Pact',
    'slot3': 'Void Syndicate',
    'slot4': 'Verdant Union',
    'slot5': null,
    'slot6': null,
  };

  // Legacy pack names were recovered; their complete content and any modern
  // DLC catalog remain canon-pending.
  static const List<String> legacyDlcPackNames = <String>[
    'Faction Ascension',
    'War Machines',
    'Void Expansion',
    'Verdant Worlds',
  ];
  static const List<String> modernDlcPackIds = <String>[];

  // Recovered modern roster names. These are reserved content identifiers,
  // not buildable actors until final costs/stats/prerequisites are approved.
  static const List<String> reservedRosterNames = <String>[
    'Rifleman',
    'Heavy Trooper',
    'Anti-Air Soldier',
    'Sniper',
    'Saboteur',
    'Engineer',
    'Spy',
    'Counter-Intelligence Officer',
    'Command Unit',
    'Light Tank',
    'Heavy Tank',
    'Artillery',
    'EMP Carrier',
    'Mobile Radar Jammer',
    'Attack Helicopter',
    'Drone Swarm',
    'Stealth Bomber',
  ];

  static const int standardUnitCap = 100;
  static const int largeBattleUnitCap = 200;

  // Prototype tuning only. The mechanics are canonical, but the exact
  // historical formulas were not recoverable and are intentionally not
  // represented as final balance.
  static const int prototypeManualRepairPointsPerStep = 5;
  static const int prototypeManualRepairCreditsPerStep = 5;
  static const int prototypeManualRepairIntervalTicks = 30;
  static const int prototypeLowPowerBreakdownIntervalTicks = 600;
  static const int prototypeLowPowerBreakdownDamage = 1;
  static const double prototypeIntegrityDiminishFactor = 0.50;

  static BuildingBlueprint building(String id) {
    return buildings.firstWhere((item) => item.id == id);
  }

  static BuildingBlueprint? buildingOrNull(String id) {
    for (final item in buildings) {
      if (item.id == id) return item;
    }
    return null;
  }

  static UnitBlueprint unit(String id) {
    return units.firstWhere((item) => item.id == id);
  }

  static UnitBlueprint? unitOrNull(String id) {
    for (final item in units) {
      if (item.id == id) return item;
    }
    return null;
  }

  static Iterable<UnitBlueprint> unitsForLane(RtsProductionLane lane) {
    return units.where((item) => item.lane == lane);
  }

  static Iterable<BuildingBlueprint> structuresForLane(
    RtsProductionLane lane,
  ) {
    return buildings.where((item) => item.lane == lane);
  }
}

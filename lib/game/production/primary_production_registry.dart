import '../buildings/building_type.dart';
import '../core/entity_id.dart';
import '../core/world_state.dart';

class PrimaryProductionRegistry {
  final Map<_FacilityKey, EntityId> _primary = <_FacilityKey, EntityId>{};

  static bool supports(BuildingType type) {
    return type == BuildingType.barracks ||
        type == BuildingType.warFactory;
  }

  EntityId? primaryFor({
    required WorldState world,
    required int teamId,
    required BuildingType type,
  }) {
    if (!supports(type)) return null;

    final key = _FacilityKey(teamId, type);
    final eligible = _eligible(
      world: world,
      teamId: teamId,
      type: type,
    );

    if (eligible.isEmpty) {
      _primary.remove(key);
      return null;
    }

    final current = _primary[key];
    if (current != null && eligible.contains(current)) {
      return current;
    }

    final fallback = eligible.first;
    _primary[key] = fallback;
    return fallback;
  }

  bool makePrimary({
    required WorldState world,
    required int teamId,
    required BuildingType type,
    required EntityId buildingId,
  }) {
    if (!supports(type)) return false;

    final eligible = _eligible(
      world: world,
      teamId: teamId,
      type: type,
    );
    if (!eligible.contains(buildingId)) return false;

    _primary[_FacilityKey(teamId, type)] = buildingId;
    return true;
  }

  bool isPrimary({
    required WorldState world,
    required int teamId,
    required BuildingType type,
    required EntityId buildingId,
  }) {
    return primaryFor(
          world: world,
          teamId: teamId,
          type: type,
        ) ==
        buildingId;
  }

  int countFor({
    required WorldState world,
    required int teamId,
    required BuildingType type,
  }) {
    if (!supports(type)) return 0;
    return _eligible(
      world: world,
      teamId: teamId,
      type: type,
    ).length;
  }

  Set<EntityId> primaryIdsForTeam({
    required WorldState world,
    required int teamId,
  }) {
    final result = <EntityId>{};
    for (final type in const <BuildingType>[
      BuildingType.barracks,
      BuildingType.warFactory,
    ]) {
      final id = primaryFor(
        world: world,
        teamId: teamId,
        type: type,
      );
      if (id != null) result.add(id);
    }
    return result;
  }

  List<EntityId> _eligible({
    required WorldState world,
    required int teamId,
    required BuildingType type,
  }) {
    final result = <EntityId>[
      for (final id in world.buildingIds)
        if (world.buildingTypes[id] == type &&
            world.buildingTeams[id]?.id == teamId)
          id,
    ];

    // Entity IDs are monotonic, so ascending order is construction order.
    result.sort((a, b) => a.value.compareTo(b.value));
    return result;
  }
}

class _FacilityKey {
  const _FacilityKey(this.teamId, this.type);

  final int teamId;
  final BuildingType type;

  @override
  bool operator ==(Object other) {
    return other is _FacilityKey &&
        other.teamId == teamId &&
        other.type == type;
  }

  @override
  int get hashCode => Object.hash(teamId, type);
}

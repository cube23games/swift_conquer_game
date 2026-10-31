import '../../sc_master/core/id/entity_id.dart';
import '../../sc_master/world/world_state.dart';

final class PrimaryFacilityRegistry {
  final Map<_PrimaryKey, EntityId> _primary = <_PrimaryKey, EntityId>{};

  static bool supports(String archetype) {
    return archetype == 'barracks' ||
        archetype == 'war_factory' ||
        archetype == 'airfield' ||
        archetype == 'naval_yard';
  }

  EntityId? primaryFor({
    required WorldState world,
    required int teamId,
    required String archetype,
  }) {
    if (!supports(archetype)) return null;
    final eligible = world.buildings.values
        .where((building) =>
            building.alive &&
            building.teamId == teamId &&
            building.archetype == archetype)
        .map((building) => building.id)
        .toList()
      ..sort();

    final key = _PrimaryKey(teamId, archetype);
    if (eligible.isEmpty) {
      _primary.remove(key);
      return null;
    }

    final current = _primary[key];
    if (current != null && eligible.contains(current)) return current;
    _primary[key] = eligible.first;
    return eligible.first;
  }

  bool makePrimary({
    required WorldState world,
    required int teamId,
    required String archetype,
    required EntityId buildingId,
  }) {
    if (!supports(archetype)) return false;
    final building = world.buildings[buildingId];
    if (building == null ||
        !building.alive ||
        building.teamId != teamId ||
        building.archetype != archetype) {
      return false;
    }
    _primary[_PrimaryKey(teamId, archetype)] = buildingId;
    return true;
  }

  bool isPrimary({
    required WorldState world,
    required int teamId,
    required EntityId buildingId,
  }) {
    final building = world.buildings[buildingId];
    if (building == null || !supports(building.archetype)) return false;
    return primaryFor(
          world: world,
          teamId: teamId,
          archetype: building.archetype,
        ) ==
        buildingId;
  }

  Set<EntityId> primaryIds({
    required WorldState world,
    required int teamId,
  }) {
    final result = <EntityId>{};
    for (final archetype in const <String>[
      'barracks',
      'war_factory',
      'airfield',
      'naval_yard',
    ]) {
      final id = primaryFor(
        world: world,
        teamId: teamId,
        archetype: archetype,
      );
      if (id != null) result.add(id);
    }
    return result;
  }
}

final class _PrimaryKey {
  final int teamId;
  final String archetype;

  const _PrimaryKey(this.teamId, this.archetype);

  @override
  bool operator ==(Object other) {
    return other is _PrimaryKey &&
        other.teamId == teamId &&
        other.archetype == archetype;
  }

  @override
  int get hashCode => Object.hash(teamId, archetype);
}

import '../../sc_master/world/world_state.dart';
import 'runtime_queue.dart';

Map<String, Object?> buildRuntimeSnapshot({
  required WorldState world,
  required Map<int, int> credits,
  required Map<int, int> powerProduced,
  required Map<int, int> powerDemand,
  required Map<int, RuntimeQueueSnapshot> structureQueues,
  required int tick,
}) {
  final teamIds = credits.keys.toList()..sort();

  final units = world.units.values
      .where((unit) => unit.alive)
      .map((unit) => <String, Object?>{
            'id': unit.id.value,
            'team': unit.teamId,
            'kind': unit.archetype,
            'x': unit.position.x,
            'y': unit.position.y,
            'hp': unit.health,
            'move': unit.moveTarget?.toJson(),
            'attack': unit.attackTarget?.value,
          })
      .toList()
    ..sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));

  final buildings = world.buildings.values
      .where((building) => building.alive)
      .map((building) => <String, Object?>{
            'id': building.id.value,
            'team': building.teamId,
            'kind': building.archetype,
            'x': building.position.x,
            'y': building.position.y,
            'hp': building.health,
            'powered': building.powered,
          })
      .toList()
    ..sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));

  return <String, Object?>{
    'tick': tick,
    'teams': <Object?>[
      for (final teamId in teamIds)
        <String, Object?>{
          'id': teamId,
          'credits': credits[teamId] ?? 0,
          'powerProduced': powerProduced[teamId] ?? 0,
          'powerDemand': powerDemand[teamId] ?? 0,
          'structureQueue': <String, Object?>{
            'count': structureQueues[teamId]?.count ?? 0,
            'current': structureQueues[teamId]?.current?.archetype,
            'progress': structureQueues[teamId]?.progress ?? 0,
            'ready': structureQueues[teamId]?.ready ?? false,
          },
        },
    ],
    'units': units,
    'buildings': buildings,
  };
}

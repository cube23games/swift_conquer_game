import '../world/world_state.dart';
import 'wreck_record.dart';

final class DeathCleanup {
  final List<WreckRecord> wrecks = [];

  void run(WorldState world) {
    final deadUnits = world.units.values.where((unit) => !unit.alive).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    for (final unit in deadUnits) {
      wrecks.add(WreckRecord(
        sourceId: unit.id,
        archetype: unit.archetype,
        position: unit.position,
        createdTick: world.tick,
      ));
      world.units.remove(unit.id);
    }

    world.buildings.removeWhere((_, building) => !building.alive);
  }
}

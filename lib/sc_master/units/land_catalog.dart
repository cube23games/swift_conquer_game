import '../world/unit_state.dart';
import 'unit_archetype.dart';

final class LandCatalog {
  static const List<UnitArchetype> generic = [
    UnitArchetype(
      id: 'infantry',
      domain: UnitDomain.land,
      cost: 100,
      health: 30,
      speed: 70,
      roles: {'anti_personnel'},
    ),
    UnitArchetype(
      id: 'engineer',
      domain: UnitDomain.land,
      cost: 250,
      health: 25,
      speed: 60,
      roles: {'repair', 'capture', 'sabotage'},
    ),
    UnitArchetype(
      id: 'tank',
      domain: UnitDomain.land,
      cost: 900,
      health: 120,
      speed: 90,
      roles: {'armor'},
    ),
    UnitArchetype(
      id: 'harvester',
      domain: UnitDomain.land,
      cost: 1200,
      health: 160,
      speed: 55,
      roles: {'economy'},
    ),
  ];
}

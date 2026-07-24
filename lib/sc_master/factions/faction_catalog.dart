import 'faction_definition.dart';
import 'faction_id.dart';

final class FactionCatalog {
  static const List<FactionDefinition> all = [
    FactionDefinition(id: FactionId.slot1, displayName: 'Faction Slot 1'),
    FactionDefinition(id: FactionId.slot2, displayName: 'Faction Slot 2'),
    FactionDefinition(id: FactionId.slot3, displayName: 'Faction Slot 3'),
    FactionDefinition(id: FactionId.slot4, displayName: 'Faction Slot 4'),
    FactionDefinition(id: FactionId.slot5, displayName: 'Faction Slot 5'),
    FactionDefinition(id: FactionId.slot6, displayName: 'Faction Slot 6'),
  ];

  static FactionDefinition byId(FactionId id) {
    return all.firstWhere((faction) => faction.id == id);
  }
}

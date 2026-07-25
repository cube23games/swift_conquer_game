import '../core/id/entity_id.dart';

final class TransportState {
  final EntityId transportId;
  final int capacity;
  final List<EntityId> passengers = [];

  TransportState({
    required this.transportId,
    required this.capacity,
  });

  bool load(EntityId unitId) {
    if (passengers.length >= capacity || passengers.contains(unitId)) {
      return false;
    }
    passengers.add(unitId);
    passengers.sort();
    return true;
  }

  bool unload(EntityId unitId) => passengers.remove(unitId);
}

import '../core/id/entity_id.dart';

final class HarvesterState {
  final EntityId unitId;
  final int capacity;
  int cargo;

  HarvesterState({
    required this.unitId,
    this.capacity = 700,
    this.cargo = 0,
  });

  int collect(int available) {
    if (available <= 0) return 0;
    final room = capacity - cargo;
    final taken = available < room ? available : room;
    cargo += taken;
    return taken;
  }

  int unload() {
    final amount = cargo;
    cargo = 0;
    return amount;
  }

  bool get full => cargo >= capacity;
}

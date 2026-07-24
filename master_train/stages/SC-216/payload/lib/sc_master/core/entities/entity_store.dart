import '../id/entity_id.dart';
import 'entity_record.dart';

final class EntityStore {
  int _next = 1;
  final Map<EntityId, EntityRecord> _records = {};

  EntityId create({required int teamId, required String kind}) {
    final id = EntityId(_next++);
    _records[id] = EntityRecord(id: id, teamId: teamId, kind: kind);
    return id;
  }

  EntityRecord? operator [](EntityId id) => _records[id];

  Iterable<EntityRecord> get alive {
    return _records.values.where((record) => record.alive);
  }

  bool destroy(EntityId id) {
    final record = _records[id];
    if (record == null || !record.alive) return false;
    record.alive = false;
    return true;
  }

  int get count => _records.length;
}

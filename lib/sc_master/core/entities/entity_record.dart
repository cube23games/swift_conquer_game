import '../id/entity_id.dart';

final class EntityRecord {
  final EntityId id;
  final int teamId;
  final String kind;
  bool alive;

  EntityRecord({
    required this.id,
    required this.teamId,
    required this.kind,
    this.alive = true,
  });
}

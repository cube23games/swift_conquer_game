import '../core/id/entity_id.dart';
import '../core/math/vec2.dart';

final class WreckRecord {
  final EntityId sourceId;
  final String archetype;
  final Vec2 position;
  final int createdTick;

  const WreckRecord({
    required this.sourceId,
    required this.archetype,
    required this.position,
    required this.createdTick,
  });
}

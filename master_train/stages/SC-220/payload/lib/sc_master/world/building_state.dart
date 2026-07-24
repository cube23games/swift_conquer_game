import '../core/id/entity_id.dart';
import '../core/math/vec2.dart';

final class BuildingState {
  final EntityId id;
  final int teamId;
  final String archetype;
  final Vec2 position;
  int health;
  final int maxHealth;
  bool powered;
  bool alive;

  BuildingState({
    required this.id,
    required this.teamId,
    required this.archetype,
    required this.position,
    required this.health,
    required this.maxHealth,
    this.powered = true,
    this.alive = true,
  });
}

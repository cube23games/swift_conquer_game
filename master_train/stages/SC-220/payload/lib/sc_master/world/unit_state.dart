import '../core/id/entity_id.dart';
import '../core/math/vec2.dart';

enum UnitDomain { land, air, naval }

final class UnitState {
  final EntityId id;
  final int teamId;
  final String archetype;
  final UnitDomain domain;
  Vec2 position;
  int health;
  final int maxHealth;
  Vec2? moveTarget;
  EntityId? attackTarget;
  bool alive;

  UnitState({
    required this.id,
    required this.teamId,
    required this.archetype,
    required this.position,
    required this.health,
    required this.maxHealth,
    this.domain = UnitDomain.land,
    this.moveTarget,
    this.attackTarget,
    this.alive = true,
  });
}

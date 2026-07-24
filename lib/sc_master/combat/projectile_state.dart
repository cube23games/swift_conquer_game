import '../core/id/entity_id.dart';
import '../core/math/vec2.dart';
import 'damage_packet.dart';

final class ProjectileState {
  final EntityId source;
  final EntityId target;
  final double speed;
  final DamagePacket damage;
  Vec2 position;
  bool active;

  ProjectileState({
    required this.source,
    required this.target,
    required this.position,
    required this.speed,
    required this.damage,
    this.active = true,
  });

  bool advance(Vec2 targetPosition, double dt) {
    final delta = targetPosition - position;
    final distance = delta.length;
    final step = speed * dt;
    if (step >= distance) {
      position = targetPosition;
      active = false;
      return true;
    }
    position = position + delta.normalized() * step;
    return false;
  }
}

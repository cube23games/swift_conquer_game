import '../core/id/entity_id.dart';
import '../core/math/vec2.dart';

final class NavalUnitState {
  final EntityId unitId;
  Vec2 position;
  Vec2? destination;
  double speed;

  NavalUnitState({
    required this.unitId,
    required this.position,
    this.destination,
    this.speed = 60,
  });

  void update(double dt) {
    final target = destination;
    if (target == null) return;
    final delta = target - position;
    final step = speed * dt;
    if (step >= delta.length) {
      position = target;
      destination = null;
    } else {
      position = position + delta.normalized() * step;
    }
  }
}

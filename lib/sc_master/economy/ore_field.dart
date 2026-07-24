import '../core/id/entity_id.dart';
import '../core/math/vec2.dart';

final class OreField {
  final EntityId id;
  final Vec2 position;
  int remaining;

  OreField({
    required this.id,
    required this.position,
    required this.remaining,
  });

  int harvest(int requested) {
    if (requested <= 0 || remaining <= 0) return 0;
    final taken = requested < remaining ? requested : remaining;
    remaining -= taken;
    return taken;
  }

  bool get depleted => remaining <= 0;
}

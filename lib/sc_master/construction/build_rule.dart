import '../core/math/vec2.dart';
import '../world/world_state.dart';

final class BuildRule {
  final double radius;

  const BuildRule({this.radius = 120});

  bool canBuild({
    required WorldState world,
    required int teamId,
    required Vec2 position,
    bool ignoreRadius = false,
  }) {
    if (ignoreRadius) return true;
    for (final building in world.buildings.values) {
      if (!building.alive || building.teamId != teamId) continue;
      if (building.position.distanceTo(position) <= radius) return true;
    }
    return false;
  }
}

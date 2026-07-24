import '../core/math/vec2.dart';
import 'grid_cell.dart';

final class ResourceSeed {
  final Vec2 position;
  final String type;
  final int amount;

  const ResourceSeed(this.position, this.type, this.amount);
}

final class MapSpec {
  final String id;
  final double width;
  final double height;
  final double cellSize;
  final List<Vec2> spawns;
  final Set<GridCell> blocked;
  final List<ResourceSeed> resources;

  const MapSpec({
    required this.id,
    required this.width,
    required this.height,
    required this.cellSize,
    this.spawns = const [],
    this.blocked = const {},
    this.resources = const [],
  });
}

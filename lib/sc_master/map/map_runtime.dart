import '../core/math/vec2.dart';
import 'grid_cell.dart';
import 'map_spec.dart';

final class MapRuntime {
  final MapSpec spec;

  const MapRuntime(this.spec);

  GridCell cellAt(Vec2 position) {
    return GridCell(
      (position.x / spec.cellSize).floor(),
      (position.y / spec.cellSize).floor(),
    );
  }

  bool contains(Vec2 position) {
    return position.x >= 0 &&
        position.y >= 0 &&
        position.x <= spec.width &&
        position.y <= spec.height;
  }

  bool isBlocked(Vec2 position) => spec.blocked.contains(cellAt(position));
}

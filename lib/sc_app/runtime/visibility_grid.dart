import '../../sc_master/core/math/vec2.dart';
import '../../sc_master/world/world_state.dart';

final class VisibilityCell {
  final int col;
  final int row;

  const VisibilityCell(this.col, this.row);

  @override
  bool operator ==(Object other) {
    return other is VisibilityCell && other.col == col && other.row == row;
  }

  @override
  int get hashCode => Object.hash(col, row);
}

final class VisibilityGrid {
  VisibilityGrid({
    required this.worldWidth,
    required this.worldHeight,
    this.cellSize = 80,
  });

  final double worldWidth;
  final double worldHeight;
  final double cellSize;

  final Map<int, Set<VisibilityCell>> _explored =
      <int, Set<VisibilityCell>>{};
  final Map<int, Set<VisibilityCell>> _visible =
      <int, Set<VisibilityCell>>{};

  int get columns => (worldWidth / cellSize).ceil();
  int get rows => (worldHeight / cellSize).ceil();

  VisibilityCell cellAt(Vec2 position) {
    return VisibilityCell(
      (position.x / cellSize).floor(),
      (position.y / cellSize).floor(),
    );
  }

  void updateForTeam(
    WorldState world,
    int teamId, {
    int unitRadiusCells = 2,
    int buildingRadiusCells = 3,
  }) {
    final visible = <VisibilityCell>{};

    for (final unit in world.units.values) {
      if (!unit.alive || unit.teamId != teamId) continue;
      _revealAround(
        visible,
        cellAt(unit.position),
        unitRadiusCells,
      );
    }

    for (final building in world.buildings.values) {
      if (!building.alive || building.teamId != teamId) continue;
      _revealAround(
        visible,
        cellAt(building.position),
        buildingRadiusCells,
      );
    }

    _visible[teamId] = visible;
    _explored.putIfAbsent(teamId, () => <VisibilityCell>{}).addAll(visible);
  }

  bool isVisible(int teamId, Vec2 position) {
    return _visible[teamId]?.contains(cellAt(position)) ?? false;
  }

  bool isExplored(int teamId, Vec2 position) {
    return _explored[teamId]?.contains(cellAt(position)) ?? false;
  }

  Set<VisibilityCell> visibleCells(int teamId) {
    return Set<VisibilityCell>.unmodifiable(
      _visible[teamId] ?? const <VisibilityCell>{},
    );
  }

  Set<VisibilityCell> exploredCells(int teamId) {
    return Set<VisibilityCell>.unmodifiable(
      _explored[teamId] ?? const <VisibilityCell>{},
    );
  }

  void _revealAround(
    Set<VisibilityCell> target,
    VisibilityCell center,
    int radius,
  ) {
    for (var dy = -radius; dy <= radius; dy += 1) {
      for (var dx = -radius; dx <= radius; dx += 1) {
        final col = center.col + dx;
        final row = center.row + dy;
        if (col < 0 || row < 0 || col >= columns || row >= rows) continue;
        if ((dx * dx) + (dy * dy) > radius * radius) continue;
        target.add(VisibilityCell(col, row));
      }
    }
  }
}

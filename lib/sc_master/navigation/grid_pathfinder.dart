import '../map/grid_cell.dart';

final class GridPathfinder {
  const GridPathfinder();

  List<GridCell> findPath({
    required GridCell start,
    required GridCell goal,
    required Set<GridCell> blocked,
    int maxVisited = 4096,
  }) {
    final queue = <GridCell>[start];
    final parent = <GridCell, GridCell?>{start: null};
    var cursor = 0;

    while (cursor < queue.length && parent.length <= maxVisited) {
      final current = queue[cursor++];
      if (current == goal) break;
      for (final next in _neighbors(current)) {
        if (blocked.contains(next) || parent.containsKey(next)) continue;
        parent[next] = current;
        queue.add(next);
      }
    }

    if (!parent.containsKey(goal)) return const [];
    final reversed = <GridCell>[];
    GridCell? current = goal;
    while (current != null) {
      reversed.add(current);
      current = parent[current];
    }
    return reversed.reversed.toList();
  }

  Iterable<GridCell> _neighbors(GridCell cell) sync* {
    yield GridCell(cell.col + 1, cell.row);
    yield GridCell(cell.col - 1, cell.row);
    yield GridCell(cell.col, cell.row + 1);
    yield GridCell(cell.col, cell.row - 1);
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/map/grid_cell.dart';
import 'package:swift_conquer_game/sc_master/navigation/grid_pathfinder.dart';

void main() {
  test('SC-225 pathfinder routes around blocked cells', () {
    final path = const GridPathfinder().findPath(
      start: const GridCell(0, 0),
      goal: const GridCell(2, 0),
      blocked: const {GridCell(1, 0)},
    );
    expect(path.first, const GridCell(0, 0));
    expect(path.last, const GridCell(2, 0));
    expect(path, isNot(contains(const GridCell(1, 0))));
  });
}

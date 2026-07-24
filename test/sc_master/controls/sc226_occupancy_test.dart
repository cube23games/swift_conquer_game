import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/core/id/entity_id.dart';
import 'package:swift_conquer_game/sc_master/map/grid_cell.dart';
import 'package:swift_conquer_game/sc_master/navigation/occupancy_grid.dart';

void main() {
  test('SC-226 one grid cell has one owner', () {
    final grid = OccupancyGrid();
    expect(grid.reserve(const GridCell(1, 1), const EntityId(1)), isTrue);
    expect(grid.reserve(const GridCell(1, 1), const EntityId(2)), isFalse);
  });
}

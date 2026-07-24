import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/core/math/vec2.dart';
import 'package:swift_conquer_game/sc_master/map/grid_cell.dart';
import 'package:swift_conquer_game/sc_master/map/map_runtime.dart';
import 'package:swift_conquer_game/sc_master/map/map_spec.dart';

void main() {
  test('SC-219 map resolves deterministic grid cells', () {
    final runtime = MapRuntime(MapSpec(
      id: 'test',
      width: 100,
      height: 100,
      cellSize: 10,
      blocked: const {GridCell(2, 3)},
    ));
    expect(runtime.isBlocked(const Vec2(25, 35)), isTrue);
  });
}

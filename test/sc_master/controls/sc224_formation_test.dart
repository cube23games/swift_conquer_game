import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/control/formation_planner.dart';
import 'package:swift_conquer_game/sc_master/core/id/entity_id.dart';
import 'package:swift_conquer_game/sc_master/core/math/vec2.dart';

void main() {
  test('SC-224 formation planning ignores input order', () {
    final planner = FormationPlanner();
    final a = planner.plan(
      units: const [EntityId(3), EntityId(1), EntityId(2)],
      destination: Vec2.zero,
    );
    final b = planner.plan(
      units: const [EntityId(2), EntityId(3), EntityId(1)],
      destination: Vec2.zero,
    );
    expect(a, b);
  });
}

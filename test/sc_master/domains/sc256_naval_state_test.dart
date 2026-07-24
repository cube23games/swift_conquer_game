import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/core/id/entity_id.dart';
import 'package:swift_conquer_game/sc_master/core/math/vec2.dart';
import 'package:swift_conquer_game/sc_master/naval/naval_unit_state.dart';

void main() {
  test('SC-256 naval movement reaches destination deterministically', () {
    final naval = NavalUnitState(
      unitId: const EntityId(1),
      position: Vec2.zero,
      destination: const Vec2(10, 0),
      speed: 10,
    )..update(1);
    expect(naval.position, const Vec2(10, 0));
    expect(naval.destination, isNull);
  });
}

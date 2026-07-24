import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/core/id/entity_id.dart';
import 'package:swift_conquer_game/sc_master/core/math/vec2.dart';

void main() {
  test('SC-213 value types are stable and comparable', () {
    expect(const EntityId(1), const EntityId(1));
    expect(const EntityId(1).compareTo(const EntityId(2)), lessThan(0));
    expect((const Vec2(3, 4)).length, 5);
  });
}

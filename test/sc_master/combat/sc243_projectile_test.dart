import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/combat/damage_packet.dart';
import 'package:swift_conquer_game/sc_master/combat/projectile_state.dart';
import 'package:swift_conquer_game/sc_master/core/id/entity_id.dart';
import 'package:swift_conquer_game/sc_master/core/math/vec2.dart';

void main() {
  test('SC-243 projectile impact is step deterministic', () {
    final projectile = ProjectileState(
      source: const EntityId(1),
      target: const EntityId(2),
      position: Vec2.zero,
      speed: 10,
      damage: const DamagePacket(
        amount: 5, type: DamageType.kinetic),
    );
    expect(projectile.advance(const Vec2(10, 0), 0.5), isFalse);
    expect(projectile.position, const Vec2(5, 0));
    expect(projectile.advance(const Vec2(10, 0), 0.5), isTrue);
  });
}

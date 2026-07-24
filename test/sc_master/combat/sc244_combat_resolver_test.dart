import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/combat/combat_resolver.dart';
import 'package:swift_conquer_game/sc_master/combat/damage_packet.dart';
import 'package:swift_conquer_game/sc_master/core/math/vec2.dart';
import 'package:swift_conquer_game/sc_master/world/world_state.dart';

void main() {
  test('SC-244 lethal damage marks target dead', () {
    final world = WorldState();
    final target = world.spawnUnit(
      teamId: 2, archetype: 'infantry', position: Vec2.zero, health: 10);
    const CombatResolver().applyDamage(
      world: world,
      target: target,
      packet: const DamagePacket(
        amount: 10, type: DamageType.kinetic),
    );
    expect(world.units[target]!.alive, isFalse);
  });
}

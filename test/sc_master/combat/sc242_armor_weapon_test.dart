import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/combat/armor_profile.dart';
import 'package:swift_conquer_game/sc_master/combat/damage_packet.dart';
import 'package:swift_conquer_game/sc_master/combat/weapon_spec.dart';

void main() {
  test('SC-242 armor applies explicit damage multipliers', () {
    const armor = ArmorProfile({DamageType.explosive: 0.5});
    expect(armor.apply(const DamagePacket(
      amount: 20, type: DamageType.explosive)), 10);
    expect(const WeaponSpec(
      id: 'cannon',
      range: 100,
      cooldownTicks: 30,
      damage: DamagePacket(amount: 10, type: DamageType.kinetic),
    ).id, 'cannon');
  });
}

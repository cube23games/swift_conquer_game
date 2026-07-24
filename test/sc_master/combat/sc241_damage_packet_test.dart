import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/combat/damage_packet.dart';

void main() {
  test('SC-241 damage packet preserves deterministic integer amount', () {
    const packet = DamagePacket(amount: 25, type: DamageType.kinetic);
    expect(packet.amount, 25);
    expect(packet.type, DamageType.kinetic);
  });
}

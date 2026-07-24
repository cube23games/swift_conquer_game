import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/superweapon/superweapon_state.dart';

void main() {
  test('SC-258 superweapon stops charging under low power', () {
    final weapon = SuperweaponState(id: 'generic', chargeTicks: 2)
      ..tick(powered: false);
    expect(weapon.progress, 0);
    weapon.tick(powered: true);
    weapon.tick(powered: true);
    expect(weapon.ready, isTrue);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/combat/combat_smoke.dart';

void main() {
  test('SC-250 combat and engineer checkpoint passes', () {
    expect(const CombatSmoke().run(), isTrue);
  });
}

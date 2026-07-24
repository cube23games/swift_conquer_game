import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/economy/economy_smoke.dart';

void main() {
  test('SC-240 base and economy checkpoint passes', () {
    expect(const EconomySmoke().run(), isTrue);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/control/control_smoke.dart';

void main() {
  test('SC-230 controls checkpoint passes', () {
    expect(const ControlSmoke().run(), isTrue);
  });
}

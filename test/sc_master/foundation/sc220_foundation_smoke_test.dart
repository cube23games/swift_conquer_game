import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/foundation/foundation_smoke.dart';

void main() {
  test('SC-220 foundation smoke is deterministic', () {
    expect(const FoundationSmoke().run(), const FoundationSmoke().run());
  });
}

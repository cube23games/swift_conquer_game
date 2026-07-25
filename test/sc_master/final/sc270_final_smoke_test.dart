import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/final/final_smoke.dart';

void main() {
  test('SC-270 full vertical-slice smoke passes', () {
    final result = const FinalSmoke().run();
    expect(result.passed, isTrue);
  });
}

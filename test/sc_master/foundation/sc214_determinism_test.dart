import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/core/random/deterministic_rng.dart';
import 'package:swift_conquer_game/sc_master/core/time/fixed_clock.dart';

void main() {
  test('SC-214 seeded sources repeat exactly', () {
    final a = DeterministicRng(7);
    final b = DeterministicRng(7);
    expect(List.generate(8, (_) => a.nextInt(1000)),
        List.generate(8, (_) => b.nextInt(1000)));

    final clock = FixedClock(stepSeconds: 0.25)..advance()..advance();
    expect(clock.tick, 2);
    expect(clock.elapsedSeconds, 0.5);
  });
}

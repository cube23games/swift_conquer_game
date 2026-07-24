import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/ai/deterministic_ai.dart';

void main() {
  test('SC-264 equal AI seeds produce equal choices', () {
    final a = DeterministicAi(seed: 99);
    final b = DeterministicAi(seed: 99);
    expect(List.generate(10, (_) => a.chooseIndex(4)),
        List.generate(10, (_) => b.chooseIndex(4)));
    expect(a.shouldThink(30), isTrue);
  });
}

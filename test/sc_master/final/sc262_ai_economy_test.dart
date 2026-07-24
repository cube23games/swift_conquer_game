import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/ai/ai_economy_planner.dart';

void main() {
  test('SC-262 AI restores low power before expansion', () {
    final decision = const AiEconomyPlanner().decide(
      funds: 2000, hasRefinery: false, lowPower: true, harvesters: 0);
    expect(decision.action, 'build_power');
  });
}

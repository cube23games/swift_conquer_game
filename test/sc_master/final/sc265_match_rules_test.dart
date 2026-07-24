import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/match/match_rules.dart';
import 'package:swift_conquer_game/sc_master/match/storm_ring.dart';

void main() {
  test('SC-265 sudden death activates on the configured tick', () {
    const rules = MatchRules(tickRate: 1, suddenDeathStartMinutes: 1);
    expect(rules.suddenDeathActive(59), isFalse);
    expect(rules.suddenDeathActive(60), isTrue);
    expect(const StormRing(
      initialRadius: 100, minimumRadius: 10, shrinkPerTick: 1)
      .radiusAt(200), 10);
  });
}

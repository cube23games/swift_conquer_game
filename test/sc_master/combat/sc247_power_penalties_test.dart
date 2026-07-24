import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/power/power_grid.dart';
import 'package:swift_conquer_game/sc_master/power/power_penalties.dart';

void main() {
  test('SC-247 low power slows systems without grounding aircraft', () {
    final penalties = PowerPenalties(
      PowerGrid(produced: 50, demand: 100));
    expect(penalties.productionSpeed, lessThan(1));
    expect(penalties.aircraftReloadSpeed, greaterThan(0));
    expect(penalties.superweaponsEnabled, isFalse);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/power/power_grid.dart';

void main() {
  test('SC-236 low power reports a fractional availability', () {
    final power = PowerGrid(produced: 50, demand: 100);
    expect(power.lowPower, isTrue);
    expect(power.availability, 0.5);
  });
}

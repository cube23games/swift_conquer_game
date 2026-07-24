import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/balance/balance_profile.dart';

void main() {
  test('SC-259 locked scale defaults remain configurable', () {
    const profile = BalanceProfile();
    expect(profile.startingFunds, 15000);
    expect(profile.baselineUnitCap, 100);
    expect(profile.highEndUnitCap, 200);
  });
}

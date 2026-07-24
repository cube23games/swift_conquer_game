import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/core/id/entity_id.dart';
import 'package:swift_conquer_game/sc_master/economy/harvester_state.dart';
import 'package:swift_conquer_game/sc_master/economy/refinery_service.dart';
import 'package:swift_conquer_game/sc_master/economy/wallet.dart';

void main() {
  test('SC-234 refinery converts unloaded ore to credits', () {
    final harvester = HarvesterState(unitId: const EntityId(1))
      ..collect(80);
    final wallet = Wallet(balance: 0);
    expect(const RefineryService().unload(
      harvester: harvester, wallet: wallet, valuePerOre: 2), 160);
    expect(wallet.balance, 160);
  });
}

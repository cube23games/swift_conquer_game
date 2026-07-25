import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/core/id/entity_id.dart';
import 'package:swift_conquer_game/sc_master/economy/harvester_state.dart';

void main() {
  test('SC-233 harvester respects capacity', () {
    final harvester = HarvesterState(
      unitId: const EntityId(1), capacity: 100);
    expect(harvester.collect(140), 100);
    expect(harvester.full, isTrue);
    expect(harvester.unload(), 100);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/air/air_reload_service.dart';
import 'package:swift_conquer_game/sc_master/air/air_unit_state.dart';
import 'package:swift_conquer_game/sc_master/core/id/entity_id.dart';

void main() {
  test('SC-255 aircraft operate while low power only slows reload', () {
    final air = AirUnitState(
      unitId: const EntityId(1), maxAmmo: 2, ammo: 0);
    const AirReloadService().tick(
      aircraft: air, speedMultiplier: 0.5, requiredProgress: 1);
    expect(air.ammo, 0);
    const AirReloadService().tick(
      aircraft: air, speedMultiplier: 0.5, requiredProgress: 1);
    expect(air.ammo, 1);
  });
}

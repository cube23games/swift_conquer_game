import '../air/air_unit_state.dart';
import '../core/id/entity_id.dart';
import '../core/math/vec2.dart';
import '../naval/naval_unit_state.dart';
import '../transport/transport_state.dart';

final class MixedDomainSmoke {
  const MixedDomainSmoke();

  bool run() {
    final aircraft = AirUnitState(
      unitId: const EntityId(1),
      maxAmmo: 2,
    );
    final naval = NavalUnitState(
      unitId: const EntityId(2),
      position: Vec2.zero,
      destination: const Vec2(10, 0),
      speed: 10,
    )..update(1);
    final transport = TransportState(
      transportId: const EntityId(3),
      capacity: 2,
    )..load(const EntityId(4));
    return aircraft.fire() &&
        naval.position == const Vec2(10, 0) &&
        transport.passengers.length == 1;
  }
}

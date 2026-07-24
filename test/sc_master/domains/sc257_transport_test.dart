import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/core/id/entity_id.dart';
import 'package:swift_conquer_game/sc_master/transport/transport_state.dart';

void main() {
  test('SC-257 transport capacity is enforced', () {
    final transport = TransportState(
      transportId: const EntityId(1), capacity: 1);
    expect(transport.load(const EntityId(2)), isTrue);
    expect(transport.load(const EntityId(3)), isFalse);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/control/mobile_input_adapter.dart';
import 'package:swift_conquer_game/sc_master/control/selection_state.dart';
import 'package:swift_conquer_game/sc_master/core/id/entity_id.dart';
import 'package:swift_conquer_game/sc_master/core/math/vec2.dart';
import 'package:swift_conquer_game/sc_master/orders/move_command.dart';

void main() {
  test('SC-229 ground tap emits a move command', () {
    final adapter = MobileInputAdapter(
      SelectionState()..replaceWith(const [EntityId(2), EntityId(1)]));
    final intent = adapter.tapGround(
      tick: 4, playerId: 1, destination: const Vec2(9, 9));
    expect((intent as CommandIntent).command, isA<MoveCommand>());
  });
}

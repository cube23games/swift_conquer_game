import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/control/selection_state.dart';
import 'package:swift_conquer_game/sc_master/core/id/entity_id.dart';

void main() {
  test('SC-221 tapping a selected item toggles only that item', () {
    final selection = SelectionState()
      ..replaceWith(const [EntityId(1), EntityId(2)]);
    selection.toggle(const EntityId(1));
    expect(selection.selected, {const EntityId(2)});
  });
}

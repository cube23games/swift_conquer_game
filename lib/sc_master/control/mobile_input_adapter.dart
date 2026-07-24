import '../core/id/entity_id.dart';
import '../core/math/vec2.dart';
import '../orders/attack_command.dart';
import '../orders/move_command.dart';
import 'selection_state.dart';

sealed class MobileIntent {
  const MobileIntent();
}

final class SelectionIntent extends MobileIntent {
  final Set<EntityId> selection;
  const SelectionIntent(this.selection);
}

final class CommandIntent extends MobileIntent {
  final Object command;
  const CommandIntent(this.command);
}

final class MobileInputAdapter {
  final SelectionState selection;

  MobileInputAdapter(this.selection);

  MobileIntent tapEntity(EntityId id) {
    selection.toggle(id);
    return SelectionIntent(selection.selected);
  }

  MobileIntent tapGround({
    required int tick,
    required int playerId,
    required Vec2 destination,
  }) {
    return CommandIntent(MoveCommand(
      tick: tick,
      playerId: playerId,
      units: selection.selected.toList()..sort(),
      destination: destination,
    ));
  }

  MobileIntent tapEnemy({
    required int tick,
    required int playerId,
    required EntityId target,
  }) {
    return CommandIntent(AttackCommand(
      tick: tick,
      playerId: playerId,
      attackers: selection.selected.toList()..sort(),
      target: target,
    ));
  }
}

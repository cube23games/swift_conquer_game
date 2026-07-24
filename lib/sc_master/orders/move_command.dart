import '../core/commands/game_command.dart';
import '../core/id/entity_id.dart';
import '../core/math/vec2.dart';

final class MoveCommand implements GameCommand {
  @override
  final int tick;
  @override
  final int playerId;
  final List<EntityId> units;
  final Vec2 destination;

  const MoveCommand({
    required this.tick,
    required this.playerId,
    required this.units,
    required this.destination,
  });

  @override
  String get type => 'move';

  @override
  Map<String, Object?> toJson() => {
        'tick': tick,
        'playerId': playerId,
        'units': units.map((id) => id.value).toList(),
        'destination': destination.toJson(),
      };
}

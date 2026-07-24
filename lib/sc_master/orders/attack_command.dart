import '../core/commands/game_command.dart';
import '../core/id/entity_id.dart';

final class AttackCommand implements GameCommand {
  @override
  final int tick;
  @override
  final int playerId;
  final List<EntityId> attackers;
  final EntityId target;

  const AttackCommand({
    required this.tick,
    required this.playerId,
    required this.attackers,
    required this.target,
  });

  @override
  String get type => 'attack';

  @override
  Map<String, Object?> toJson() => {
        'tick': tick,
        'playerId': playerId,
        'attackers': attackers.map((id) => id.value).toList(),
        'target': target.value,
      };
}

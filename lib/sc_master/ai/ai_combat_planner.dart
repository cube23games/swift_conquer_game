import '../core/id/entity_id.dart';
import 'ai_perception.dart';

final class AiCombatDecision {
  final List<EntityId> attackers;
  final EntityId? target;

  const AiCombatDecision({
    required this.attackers,
    required this.target,
  });
}

final class AiCombatPlanner {
  const AiCombatPlanner();

  AiCombatDecision decide(AiPerception perception) {
    final target = perception.enemyBuildings.isNotEmpty
        ? perception.enemyBuildings.first
        : perception.enemyUnits.isNotEmpty
            ? perception.enemyUnits.first
            : null;
    return AiCombatDecision(
      attackers: List.unmodifiable(perception.friendlyUnits),
      target: target,
    );
  }
}

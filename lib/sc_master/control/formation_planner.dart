import 'dart:math' as math;
import '../core/id/entity_id.dart';
import '../core/math/vec2.dart';

final class FormationPlanner {
  const FormationPlanner();

  Map<EntityId, Vec2> plan({
    required Iterable<EntityId> units,
    required Vec2 destination,
    double spacing = 36,
  }) {
    final ordered = units.toList()..sort();
    if (ordered.isEmpty) return const {};
    final columns = math.max(1, math.sqrt(ordered.length).ceil()).toInt();
    final result = <EntityId, Vec2>{};

    for (var index = 0; index < ordered.length; index += 1) {
      final row = index ~/ columns;
      final col = index % columns;
      final rowCount =
          math.min(columns, ordered.length - row * columns).toInt();
      final lateral = (col - (rowCount - 1) / 2) * spacing;
      final depth = row * spacing;
      result[ordered[index]] = Vec2(
        destination.x + lateral,
        destination.y + depth,
      );
    }
    return result;
  }
}

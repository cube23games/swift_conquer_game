import '../world/unit_state.dart';

final class UnitArchetype {
  final String id;
  final UnitDomain domain;
  final int cost;
  final int health;
  final double speed;
  final Set<String> roles;

  const UnitArchetype({
    required this.id,
    required this.domain,
    required this.cost,
    required this.health,
    required this.speed,
    this.roles = const {},
  });
}

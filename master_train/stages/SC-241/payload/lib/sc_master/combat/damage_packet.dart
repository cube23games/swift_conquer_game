enum DamageType { kinetic, explosive, energy, sabotage }

final class DamagePacket {
  final int amount;
  final DamageType type;

  const DamagePacket({
    required this.amount,
    required this.type,
  }) : assert(amount >= 0);
}

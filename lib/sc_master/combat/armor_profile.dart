import 'damage_packet.dart';

final class ArmorProfile {
  final Map<DamageType, double> multipliers;

  const ArmorProfile(this.multipliers);

  int apply(DamagePacket packet) {
    final multiplier = multipliers[packet.type] ?? 1;
    return (packet.amount * multiplier)
        .round()
        .clamp(0, 1 << 30)
        .toInt();
  }
}

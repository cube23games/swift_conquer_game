import 'damage_packet.dart';

final class WeaponSpec {
  final String id;
  final double range;
  final int cooldownTicks;
  final DamagePacket damage;

  const WeaponSpec({
    required this.id,
    required this.range,
    required this.cooldownTicks,
    required this.damage,
  });
}

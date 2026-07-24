import '../core/id/entity_id.dart';
import '../world/world_state.dart';
import 'armor_profile.dart';
import 'damage_packet.dart';

final class CombatResolver {
  const CombatResolver();

  int applyDamage({
    required WorldState world,
    required EntityId target,
    required DamagePacket packet,
    ArmorProfile armor = const ArmorProfile({}),
  }) {
    final applied = armor.apply(packet);
    final unit = world.units[target];
    if (unit != null && unit.alive) {
      unit.health = (unit.health - applied)
          .clamp(0, unit.maxHealth)
          .toInt();
      if (unit.health == 0) world.destroy(target);
      return applied;
    }
    final building = world.buildings[target];
    if (building != null && building.alive) {
      building.health = (building.health - applied)
          .clamp(0, building.maxHealth)
          .toInt();
      if (building.health == 0) world.destroy(target);
      return applied;
    }
    return 0;
  }
}

import '../core/id/entity_id.dart';

final class AirUnitState {
  final EntityId unitId;
  final int maxAmmo;
  int ammo;
  double reloadProgress;

  AirUnitState({
    required this.unitId,
    required this.maxAmmo,
    int? ammo,
    this.reloadProgress = 0,
  }) : ammo = ammo ?? maxAmmo;

  bool fire() {
    if (ammo <= 0) return false;
    ammo -= 1;
    return true;
  }
}

import 'air_unit_state.dart';

final class AirReloadService {
  const AirReloadService();

  bool tick({
    required AirUnitState aircraft,
    double speedMultiplier = 1,
    double requiredProgress = 100,
  }) {
    if (aircraft.ammo >= aircraft.maxAmmo || speedMultiplier <= 0) {
      return false;
    }
    aircraft.reloadProgress += speedMultiplier;
    if (aircraft.reloadProgress < requiredProgress) return false;
    aircraft.reloadProgress = 0;
    aircraft.ammo += 1;
    return true;
  }
}

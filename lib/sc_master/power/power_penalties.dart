import 'power_grid.dart';

final class PowerPenalties {
  final PowerGrid grid;

  const PowerPenalties(this.grid);

  double get productionSpeed => grid.lowPower
      ? (0.35 + 0.65 * grid.availability)
      : 1;

  double get engineerRepairSpeed => grid.lowPower
      ? (0.5 * grid.availability).clamp(0.1, 0.5).toDouble()
      : 1;

  double get aircraftReloadSpeed => grid.lowPower
      ? (0.4 + 0.6 * grid.availability)
      : 1;

  bool get superweaponsEnabled => !grid.lowPower;
}

final class PowerGrid {
  int produced;
  int demand;

  PowerGrid({
    this.produced = 0,
    this.demand = 0,
  });

  int get surplus => produced - demand;
  bool get lowPower => demand > produced;

  double get availability {
    if (demand <= 0) return 1;
    return (produced / demand).clamp(0.0, 1.0).toDouble();
  }
}

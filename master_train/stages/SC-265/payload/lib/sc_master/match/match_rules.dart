final class MatchRules {
  final int tickRate;
  final int targetMinutes;
  final int suddenDeathStartMinutes;

  const MatchRules({
    this.tickRate = 60,
    this.targetMinutes = 15,
    this.suddenDeathStartMinutes = 12,
  });

  int get targetTicks => tickRate * 60 * targetMinutes;
  int get suddenDeathTick => tickRate * 60 * suddenDeathStartMinutes;

  bool suddenDeathActive(int tick) => tick >= suddenDeathTick;
}

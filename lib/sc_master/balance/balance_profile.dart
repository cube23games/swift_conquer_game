final class BalanceProfile {
  final int startingFunds;
  final int baselineUnitCap;
  final int highEndUnitCap;
  final int expectedMatchMinutes;

  const BalanceProfile({
    this.startingFunds = 15000,
    this.baselineUnitCap = 100,
    this.highEndUnitCap = 200,
    this.expectedMatchMinutes = 15,
  });

  Map<String, int> toJson() => {
        'startingFunds': startingFunds,
        'baselineUnitCap': baselineUnitCap,
        'highEndUnitCap': highEndUnitCap,
        'expectedMatchMinutes': expectedMatchMinutes,
      };
}

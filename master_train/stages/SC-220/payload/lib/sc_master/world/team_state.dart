final class TeamState {
  final int id;
  int funds;
  int powerProduced;
  int powerUsed;
  int storageCapacity;

  TeamState({
    required this.id,
    this.funds = 15000,
    this.powerProduced = 0,
    this.powerUsed = 0,
    this.storageCapacity = 0,
  });

  bool get lowPower => powerUsed > powerProduced;
}

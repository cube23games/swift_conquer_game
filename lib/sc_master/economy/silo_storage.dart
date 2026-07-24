final class SiloStorage {
  int capacity;
  int stored;

  SiloStorage({
    this.capacity = 0,
    this.stored = 0,
  });

  int deposit(int amount) {
    if (amount <= 0) return 0;
    final room = (capacity - stored).clamp(0, capacity).toInt();
    final accepted = amount < room ? amount : room;
    stored += accepted;
    return accepted;
  }

  int withdraw(int amount) {
    if (amount <= 0) return 0;
    final removed = amount < stored ? amount : stored;
    stored -= removed;
    return removed;
  }
}

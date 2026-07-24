final class SuperweaponState {
  final String id;
  final int chargeTicks;
  int progress = 0;
  bool ready = false;

  SuperweaponState({
    required this.id,
    required this.chargeTicks,
  });

  void tick({required bool powered}) {
    if (!powered || ready) return;
    progress += 1;
    if (progress >= chargeTicks) {
      progress = chargeTicks;
      ready = true;
    }
  }

  bool fire() {
    if (!ready) return false;
    ready = false;
    progress = 0;
    return true;
  }
}

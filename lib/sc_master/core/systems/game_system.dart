abstract interface class GameSystem<W> {
  String get name;
  void update(double dt, W world);
}

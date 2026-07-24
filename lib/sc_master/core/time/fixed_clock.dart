final class FixedClock {
  final double stepSeconds;
  int tick = 0;
  double elapsedSeconds = 0;

  FixedClock({this.stepSeconds = 1 / 60})
      : assert(stepSeconds > 0);

  void advance() {
    tick += 1;
    elapsedSeconds = tick * stepSeconds;
  }

  void reset() {
    tick = 0;
    elapsedSeconds = 0;
  }
}

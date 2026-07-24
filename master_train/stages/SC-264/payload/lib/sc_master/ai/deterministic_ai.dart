import '../core/random/deterministic_rng.dart';

final class DeterministicAi {
  final DeterministicRng rng;
  final int thinkEveryTicks;

  DeterministicAi({
    required int seed,
    this.thinkEveryTicks = 30,
  }) : rng = DeterministicRng(seed);

  bool shouldThink(int tick) {
    return tick > 0 && tick % thinkEveryTicks == 0;
  }

  int chooseIndex(int optionCount) {
    return rng.nextInt(optionCount);
  }
}

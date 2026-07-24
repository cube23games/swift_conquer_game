final class DeterministicRng {
  int _state;

  DeterministicRng(int seed) : _state = seed & 0x7fffffff;

  int nextInt(int maxExclusive) {
    if (maxExclusive <= 0) {
      throw ArgumentError.value(maxExclusive, 'maxExclusive');
    }
    _state = ((_state * 1103515245) + 12345) & 0x7fffffff;
    return _state % maxExclusive;
  }

  double nextDouble() => nextInt(1 << 24) / (1 << 24);

  int get state => _state;
}

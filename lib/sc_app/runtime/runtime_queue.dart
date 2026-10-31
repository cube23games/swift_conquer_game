final class RuntimeOrder {
  final String archetype;
  final String label;
  final int cost;
  final int buildTicks;

  const RuntimeOrder({
    required this.archetype,
    required this.label,
    required this.cost,
    required this.buildTicks,
  });
}

final class RuntimeQueueSnapshot {
  final RuntimeOrder? current;
  final int count;
  final double progress;
  final bool ready;
  final int limit;

  const RuntimeQueueSnapshot({
    required this.current,
    required this.count,
    required this.progress,
    required this.ready,
    required this.limit,
  });
}

final class RuntimeBuildQueue {
  RuntimeBuildQueue({this.limit = 5});

  final int limit;
  final List<RuntimeOrder> _orders = <RuntimeOrder>[];
  double _progress = 0;
  RuntimeOrder? _ready;

  bool enqueue(RuntimeOrder order) {
    if (_orders.length + (_ready == null ? 0 : 1) >= limit) return false;
    _orders.add(order);
    return true;
  }

  RuntimeOrder? cancelLast() {
    if (_orders.isNotEmpty) return _orders.removeLast();
    if (_ready != null) {
      final order = _ready;
      _ready = null;
      _progress = 0;
      return order;
    }
    return null;
  }

  void tick(double speedMultiplier) {
    if (_ready != null || _orders.isEmpty || speedMultiplier <= 0) return;
    final current = _orders.first;
    if (current.buildTicks <= 0) {
      _ready = _orders.removeAt(0);
      _progress = 0;
      return;
    }

    _progress += speedMultiplier;
    if (_progress >= current.buildTicks) {
      _ready = _orders.removeAt(0);
      _progress = 0;
    }
  }

  RuntimeOrder? get readyOrder => _ready;

  RuntimeOrder? acceptReady() {
    final order = _ready;
    _ready = null;
    return order;
  }

  RuntimeQueueSnapshot get snapshot {
    final current = _ready ?? (_orders.isEmpty ? null : _orders.first);
    final ready = _ready != null;
    final buildTicks = current?.buildTicks ?? 0;
    final progress = ready
        ? 1.0
        : buildTicks <= 0
            ? 0.0
            : (_progress / buildTicks).clamp(0.0, 1.0).toDouble();
    return RuntimeQueueSnapshot(
      current: current,
      count: _orders.length + (ready ? 1 : 0),
      progress: progress,
      ready: ready,
      limit: limit,
    );
  }

  bool get isEmpty => _orders.isEmpty && _ready == null;
}

import '../core/entity_id.dart';
import '../core/world_state.dart';
import 'production_unit_type.dart';

class ProductionQueueSnapshot {
  const ProductionQueueSnapshot({
    required this.buildingId,
    required this.current,
    required this.totalOrders,
    required this.progress,
    required this.ready,
    required this.capacity,
  });

  final EntityId buildingId;
  final ProductionUnitType? current;
  final int totalOrders;
  final double progress;
  final bool ready;
  final int capacity;
}

class FacilityProductionQueues {
  FacilityProductionQueues({this.capacity = 5});

  final int capacity;
  final Map<EntityId, _FacilityQueue> _queues = <EntityId, _FacilityQueue>{};

  bool enqueue({
    required WorldState world,
    required EntityId buildingId,
    required ProductionUnitType item,
  }) {
    if (!world.buildingIds.contains(buildingId)) return false;
    if (world.buildingTypes[buildingId] != item.producer) return false;

    final queue = _queues.putIfAbsent(buildingId, _FacilityQueue.new);
    if (queue.orders.length >= capacity) return false;

    final wasEmpty = queue.orders.isEmpty;
    queue.orders.add(item);
    if (wasEmpty) {
      queue.remainingSeconds = item.prototypeBuildSeconds;
    }
    return true;
  }

  void tick({
    required double dt,
    required WorldState world,
  }) {
    if (dt <= 0) return;
    _removeMissingBuildings(world);

    for (final queue in _queues.values) {
      if (queue.orders.isEmpty) continue;
      if (queue.remainingSeconds <= 0) continue;
      queue.remainingSeconds = (queue.remainingSeconds - dt)
          .clamp(0.0, double.infinity)
          .toDouble();
    }
  }

  List<ProductionQueueSnapshot> readySnapshots({
    required WorldState world,
  }) {
    _removeMissingBuildings(world);
    final result = <ProductionQueueSnapshot>[];

    for (final entry in _queues.entries) {
      final snapshot = snapshotFor(
        world: world,
        buildingId: entry.key,
      );
      if (snapshot != null && snapshot.ready) {
        result.add(snapshot);
      }
    }

    result.sort((a, b) => a.buildingId.value.compareTo(b.buildingId.value));
    return result;
  }

  bool consumeReady(EntityId buildingId) {
    final queue = _queues[buildingId];
    if (queue == null ||
        queue.orders.isEmpty ||
        queue.remainingSeconds > 0) {
      return false;
    }

    queue.orders.removeAt(0);
    if (queue.orders.isEmpty) {
      _queues.remove(buildingId);
      return true;
    }

    queue.remainingSeconds =
        queue.orders.first.prototypeBuildSeconds;
    return true;
  }

  bool cancelLast(EntityId buildingId) {
    final queue = _queues[buildingId];
    if (queue == null || queue.orders.isEmpty) return false;

    queue.orders.removeLast();
    if (queue.orders.isEmpty) {
      _queues.remove(buildingId);
    }
    return true;
  }

  int queueCount(EntityId buildingId) {
    return _queues[buildingId]?.orders.length ?? 0;
  }

  ProductionQueueSnapshot? snapshotFor({
    required WorldState world,
    required EntityId buildingId,
  }) {
    if (!world.buildingIds.contains(buildingId)) {
      _queues.remove(buildingId);
      return null;
    }

    final queue = _queues[buildingId];
    if (queue == null || queue.orders.isEmpty) return null;

    final current = queue.orders.first;
    final duration = current.prototypeBuildSeconds;
    final progress = duration <= 0
        ? 1.0
        : (1.0 - (queue.remainingSeconds / duration))
            .clamp(0.0, 1.0)
            .toDouble();

    return ProductionQueueSnapshot(
      buildingId: buildingId,
      current: current,
      totalOrders: queue.orders.length,
      progress: progress,
      ready: queue.remainingSeconds <= 0,
      capacity: capacity,
    );
  }

  Map<EntityId, ProductionQueueSnapshot> snapshotsForWorld({
    required WorldState world,
  }) {
    _removeMissingBuildings(world);
    final result = <EntityId, ProductionQueueSnapshot>{};

    for (final id in _queues.keys) {
      final snapshot = snapshotFor(
        world: world,
        buildingId: id,
      );
      if (snapshot != null) {
        result[id] = snapshot;
      }
    }

    return result;
  }

  void _removeMissingBuildings(WorldState world) {
    final missing = <EntityId>[
      for (final id in _queues.keys)
        if (!world.buildingIds.contains(id)) id,
    ];
    for (final id in missing) {
      _queues.remove(id);
    }
  }
}

class _FacilityQueue {
  final List<ProductionUnitType> orders = <ProductionUnitType>[];
  double remainingSeconds = 0;
}

import '../core/id/entity_id.dart';
import '../map/grid_cell.dart';

final class OccupancyGrid {
  final Map<GridCell, EntityId> _occupants = {};

  bool reserve(GridCell cell, EntityId entity) {
    final current = _occupants[cell];
    if (current != null && current != entity) return false;
    _occupants[cell] = entity;
    return true;
  }

  void releaseEntity(EntityId entity) {
    _occupants.removeWhere((_, value) => value == entity);
  }

  EntityId? occupantAt(GridCell cell) => _occupants[cell];

  bool isFree(GridCell cell) => !_occupants.containsKey(cell);
}

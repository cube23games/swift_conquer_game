import '../core/id/entity_id.dart';

final class SelectionState {
  final Set<EntityId> _selected = {};

  Set<EntityId> get selected => Set.unmodifiable(_selected);

  bool contains(EntityId id) => _selected.contains(id);

  void replaceWith(Iterable<EntityId> ids) {
    _selected
      ..clear()
      ..addAll(ids);
  }

  void toggle(EntityId id) {
    if (!_selected.remove(id)) {
      _selected.add(id);
    }
  }

  void clear() => _selected.clear();

  int get length => _selected.length;
}

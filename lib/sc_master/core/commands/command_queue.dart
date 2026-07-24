import 'game_command.dart';

final class CommandQueue {
  final List<GameCommand> _items = [];

  void add(GameCommand command) {
    _items.add(command);
    _items.sort((a, b) {
      final tickOrder = a.tick.compareTo(b.tick);
      return tickOrder != 0 ? tickOrder : a.playerId.compareTo(b.playerId);
    });
  }

  List<GameCommand> takeForTick(int tick) {
    final ready = _items.where((item) => item.tick == tick).toList();
    _items.removeWhere((item) => item.tick == tick);
    return List.unmodifiable(ready);
  }

  int get length => _items.length;
}

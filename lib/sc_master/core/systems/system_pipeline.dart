import 'game_system.dart';

final class SystemPipeline<W> {
  final List<GameSystem<W>> systems;

  SystemPipeline(Iterable<GameSystem<W>> systems)
      : systems = List.unmodifiable(systems);

  void update(double dt, W world) {
    for (final system in systems) {
      system.update(dt, world);
    }
  }

  List<String> get names => systems.map((system) => system.name).toList();
}

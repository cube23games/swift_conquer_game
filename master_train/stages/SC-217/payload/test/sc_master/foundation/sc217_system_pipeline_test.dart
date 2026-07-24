import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/core/systems/game_system.dart';
import 'package:swift_conquer_game/sc_master/core/systems/system_pipeline.dart';

final class _System implements GameSystem<List<String>> {
  @override
  final String name;
  _System(this.name);
  @override
  void update(double dt, List<String> world) => world.add(name);
}

void main() {
  test('SC-217 pipeline order is deterministic', () {
    final world = <String>[];
    SystemPipeline([_System('a'), _System('b')]).update(1, world);
    expect(world, ['a', 'b']);
  });
}

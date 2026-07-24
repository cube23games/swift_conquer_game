import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/core/commands/command_queue.dart';
import 'package:swift_conquer_game/sc_master/core/commands/game_command.dart';

final class _Command implements GameCommand {
  @override
  final int tick;
  @override
  final int playerId;
  _Command(this.tick, this.playerId);
  @override
  String get type => 'test';
  @override
  Map<String, Object?> toJson() => {'tick': tick, 'playerId': playerId};
}

void main() {
  test('SC-215 queue orders commands by tick and player', () {
    final queue = CommandQueue()
      ..add(_Command(2, 2))
      ..add(_Command(1, 3))
      ..add(_Command(1, 1));
    expect(queue.takeForTick(1).map((e) => e.playerId), [1, 3]);
    expect(queue.length, 1);
  });
}

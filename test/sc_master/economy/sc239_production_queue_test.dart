import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/production/production_item.dart';
import 'package:swift_conquer_game/sc_master/production/production_queue.dart';

void main() {
  test('SC-239 production completes only after required ticks', () {
    final queue = ProductionQueue()
      ..enqueue(const ProductionItem(
        archetype: 'infantry', cost: 100, buildTicks: 2));
    expect(queue.tick(), isNull);
    expect(queue.tick()!.archetype, 'infantry');
  });
}

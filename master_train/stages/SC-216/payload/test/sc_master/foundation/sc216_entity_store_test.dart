import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/core/entities/entity_store.dart';

void main() {
  test('SC-216 store never reuses an entity id', () {
    final store = EntityStore();
    final first = store.create(teamId: 1, kind: 'unit');
    expect(store.destroy(first), isTrue);
    final second = store.create(teamId: 1, kind: 'unit');
    expect(second.value, greaterThan(first.value));
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/factions/faction_catalog.dart';

void main() {
  test('SC-251 catalog preserves six pending canonical slots', () {
    expect(FactionCatalog.all, hasLength(6));
    expect(FactionCatalog.all.every(
      (faction) => faction.canonicalDataPending), isTrue);
  });
}

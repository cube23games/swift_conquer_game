import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/units/land_catalog.dart';

void main() {
  test('SC-254 generic land catalog covers core roles', () {
    final roles = LandCatalog.generic.expand((unit) => unit.roles).toSet();
    expect(roles, containsAll(['repair', 'armor', 'economy']));
  });
}

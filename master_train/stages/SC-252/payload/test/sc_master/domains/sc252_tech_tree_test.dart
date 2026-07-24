import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/tech/tech_node.dart';
import 'package:swift_conquer_game/sc_master/tech/tech_tree.dart';

void main() {
  test('SC-252 prerequisites gate technology access', () {
    final tree = TechTree(const [
      TechNode(id: 'base'),
      TechNode(id: 'advanced', prerequisites: {'base'}),
    ]);
    expect(tree.available({}), {'base'});
    expect(tree.available({'base'}), {'advanced'});
  });
}

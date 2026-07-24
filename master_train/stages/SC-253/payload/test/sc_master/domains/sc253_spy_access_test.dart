import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/spy/tech_access.dart';

void main() {
  test('SC-253 selling source removes stolen tech for ten percent', () {
    final access = TechAccess()..grantStolen(1, ['naval']);
    expect(access.stolenFor(1), {'naval'});
    expect(access.removeBySellingSource(
      teamId: 1, sourceFaceValue: 1000), 100);
    expect(access.stolenFor(1), isEmpty);
  });
}

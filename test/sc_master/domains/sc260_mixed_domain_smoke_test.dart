import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/domains/mixed_domain_smoke.dart';

void main() {
  test('SC-260 mixed-domain checkpoint passes', () {
    expect(const MixedDomainSmoke().run(), isTrue);
  });
}

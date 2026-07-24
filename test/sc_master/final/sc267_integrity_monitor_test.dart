import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/integrity/integrity_monitor.dart';

void main() {
  test('SC-267 repeated mismatches escalate deterministically', () {
    final monitor = IntegrityMonitor();
    expect(monitor.inspect(
      teamId: 1, reportedHash: 1, authoritativeHash: 2).response,
      IntegrityResponse.markSuspected);
    expect(monitor.inspect(
      teamId: 1, reportedHash: 1, authoritativeHash: 2).response,
      IntegrityResponse.diminishAssets);
    expect(monitor.inspect(
      teamId: 1, reportedHash: 1, authoritativeHash: 2).response,
      IntegrityResponse.eliminate);
  });
}

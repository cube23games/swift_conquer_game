import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/core/replay/replay_verifier.dart';

void main() {
  test('SC-268 replay verifier rejects divergent state', () {
    const verifier = ReplayVerifier();
    expect(verifier.verify(
      expectedState: {'tick': 1},
      replayedState: {'tick': 1},
    ).matched, isTrue);
    expect(verifier.verify(
      expectedState: {'tick': 1},
      replayedState: {'tick': 2},
    ).matched, isFalse);
  });
}

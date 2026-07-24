import 'state_hasher.dart';

final class ReplayVerification {
  final bool matched;
  final int expectedHash;
  final int actualHash;

  const ReplayVerification({
    required this.matched,
    required this.expectedHash,
    required this.actualHash,
  });
}

final class ReplayVerifier {
  final StateHasher hasher;

  const ReplayVerifier({this.hasher = const StateHasher()});

  ReplayVerification verify({
    required Object expectedState,
    required Object replayedState,
  }) {
    final expected = hasher.hashJson(expectedState);
    final actual = hasher.hashJson(replayedState);
    return ReplayVerification(
      matched: expected == actual,
      expectedHash: expected,
      actualHash: actual,
    );
  }
}

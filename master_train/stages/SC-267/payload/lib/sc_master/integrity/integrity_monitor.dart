enum IntegrityResponse {
  none,
  markSuspected,
  diminishAssets,
  eliminate,
}

final class IntegrityFinding {
  final int teamId;
  final String code;
  final IntegrityResponse response;

  const IntegrityFinding({
    required this.teamId,
    required this.code,
    required this.response,
  });
}

final class IntegrityMonitor {
  final Map<int, int> _strikes = {};

  IntegrityFinding inspect({
    required int teamId,
    required int reportedHash,
    required int authoritativeHash,
  }) {
    if (reportedHash == authoritativeHash) {
      return IntegrityFinding(
        teamId: teamId,
        code: 'clean',
        response: IntegrityResponse.none,
      );
    }
    final strikes = (_strikes[teamId] ?? 0) + 1;
    _strikes[teamId] = strikes;
    final response = strikes >= 3
        ? IntegrityResponse.eliminate
        : strikes == 2
            ? IntegrityResponse.diminishAssets
            : IntegrityResponse.markSuspected;
    return IntegrityFinding(
      teamId: teamId,
      code: 'state_hash_mismatch',
      response: response,
    );
  }
}

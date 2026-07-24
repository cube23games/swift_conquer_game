final class AiEconomyDecision {
  final String action;
  final String reason;

  const AiEconomyDecision(this.action, this.reason);
}

final class AiEconomyPlanner {
  const AiEconomyPlanner();

  AiEconomyDecision decide({
    required int funds,
    required bool hasRefinery,
    required bool lowPower,
    required int harvesters,
  }) {
    if (lowPower && funds >= 800) {
      return const AiEconomyDecision('build_power', 'restore power');
    }
    if (!hasRefinery && funds >= 1500) {
      return const AiEconomyDecision('build_refinery', 'unlock ore income');
    }
    if (harvesters < 2 && funds >= 1200) {
      return const AiEconomyDecision('produce_harvester', 'increase income');
    }
    return const AiEconomyDecision('save', 'preserve funds');
  }
}

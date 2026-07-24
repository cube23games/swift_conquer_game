import '../combat/combat_smoke.dart';
import '../control/control_smoke.dart';
import '../domains/mixed_domain_smoke.dart';
import '../economy/economy_smoke.dart';
import '../foundation/foundation_smoke.dart';
import '../ui/sc_master_demo_controller.dart';

final class FinalSmokeResult {
  final bool foundation;
  final bool controls;
  final bool economy;
  final bool combat;
  final bool domains;
  final bool interactiveSlice;

  const FinalSmokeResult({
    required this.foundation,
    required this.controls,
    required this.economy,
    required this.combat,
    required this.domains,
    required this.interactiveSlice,
  });

  bool get passed =>
      foundation &&
      controls &&
      economy &&
      combat &&
      domains &&
      interactiveSlice;
}

final class FinalSmoke {
  const FinalSmoke();

  FinalSmokeResult run() {
    final controller = ScMasterDemoController()
      ..moveMobileHq()
      ..deployHq()
      ..harvestOre()
      ..spawnEnemy()
      ..attackEnemy()
      ..attackEnemy();
    return FinalSmokeResult(
      foundation: const FoundationSmoke().run() != 0,
      controls: const ControlSmoke().run(),
      economy: const EconomySmoke().run(),
      combat: const CombatSmoke().run(),
      domains: const MixedDomainSmoke().run(),
      interactiveSlice: controller.hq != null &&
          controller.wallet.balance > 15000 &&
          controller.message == 'Enemy destroyed.',
    );
  }
}

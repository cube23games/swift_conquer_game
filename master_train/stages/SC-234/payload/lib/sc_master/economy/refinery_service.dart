import 'harvester_state.dart';
import 'wallet.dart';

final class RefineryService {
  const RefineryService();

  int unload({
    required HarvesterState harvester,
    required Wallet wallet,
    int valuePerOre = 1,
  }) {
    if (valuePerOre <= 0) {
      throw ArgumentError.value(valuePerOre, 'valuePerOre');
    }
    final ore = harvester.unload();
    final credits = ore * valuePerOre;
    wallet.credit(credits);
    return credits;
  }
}

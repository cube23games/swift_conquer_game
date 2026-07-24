import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/economy/silo_storage.dart';

void main() {
  test('SC-235 silo rejects overflow honestly', () {
    final silo = SiloStorage(capacity: 100);
    expect(silo.deposit(130), 100);
    expect(silo.stored, 100);
  });
}

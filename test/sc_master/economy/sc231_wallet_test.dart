import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/economy/wallet.dart';

void main() {
  test('SC-231 wallet never spends below zero', () {
    final wallet = Wallet(balance: 100);
    expect(wallet.spend(101), isFalse);
    expect(wallet.balance, 100);
    expect(wallet.spend(40), isTrue);
    expect(wallet.balance, 60);
  });
}

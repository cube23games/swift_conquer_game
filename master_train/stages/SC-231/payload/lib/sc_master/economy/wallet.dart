final class Wallet {
  int balance;

  Wallet({this.balance = 15000});

  bool canAfford(int amount) => amount >= 0 && balance >= amount;

  bool spend(int amount) {
    if (!canAfford(amount)) return false;
    balance -= amount;
    return true;
  }

  void credit(int amount) {
    if (amount < 0) throw ArgumentError.value(amount, 'amount');
    balance += amount;
  }
}

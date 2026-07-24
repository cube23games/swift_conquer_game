import 'production_item.dart';

final class ProductionQueue {
  final List<ProductionItem> _items = [];
  int progress = 0;

  void enqueue(ProductionItem item) => _items.add(item);

  ProductionItem? tick({double speedMultiplier = 1}) {
    if (_items.isEmpty || speedMultiplier <= 0) return null;
    progress += speedMultiplier.ceil();
    final current = _items.first;
    if (progress < current.buildTicks) return null;
    progress = 0;
    return _items.removeAt(0);
  }

  List<ProductionItem> get items => List.unmodifiable(_items);
}

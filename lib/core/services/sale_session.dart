import '../../domain/entities/sale_item.dart';

class SaleSession {
  SaleSession._();

  static final List<SaleItem> _items = <SaleItem>[];

  static List<SaleItem> get items => List.unmodifiable(_items);

  static void addAll(Iterable<SaleItem> items) {
    _items.addAll(items);
  }

  static void clear() {
    _items.clear();
  }
}

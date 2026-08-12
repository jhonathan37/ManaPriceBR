import 'sale_item.dart';

class BatchLookupResult {
  const BatchLookupResult({required this.items, required this.failedNames});

  final List<SaleItem> items;
  final List<String> failedNames;

  int get total => items.length + failedNames.length;
  int get successful => items.length;
  double get referenceTotal =>
      items.fold(0, (sum, item) => sum + item.referencePrice);
  double get finalTotal =>
      items.fold(0, (sum, item) => sum + item.finalValue);
}

import 'price_result.dart';

class BatchItem {
  const BatchItem({required this.name, this.result, this.error});

  final String name;
  final PriceResult? result;
  final String? error;

  bool get completed => result != null || error != null;
  bool get found => result != null;
}

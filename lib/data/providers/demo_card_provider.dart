import '../../domain/entities/sale_item.dart';

class DemoCardProvider {
  const DemoCardProvider._();

  static const Map<String, double> _prices = {
    'the one ring': 250.0,
    'sol ring': 8.0,
    'command tower': 3.0,
    'lightning bolt': 12.0,
    'counterspell': 6.0,
  };

  static Future<SaleItem?> find(
    String cardName, {
    double discountPercent = 20,
  }) async {
    final normalized = cardName.trim().toLowerCase();
    final price = _prices[normalized];
    if (price == null) return null;

    return SaleItem(
      cardName: cardName.trim(),
      referencePrice: price,
      discountPercent: discountPercent,
    );
  }
}

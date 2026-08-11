import '../../domain/entities/card_sale_result.dart';

class TestCatalogProvider {
  const TestCatalogProvider._();

  static const Map<String, double> prices = {
    'the one ring': 250.0,
    'sol ring': 8.0,
    'command tower': 3.0,
  };

  static CardSaleResult? lookup(String name, {double discountPercent = 20}) {
    final key = name.trim().toLowerCase();
    final price = prices[key];
    if (price == null) return null;
    final discount = discountPercent.clamp(0, 100).toDouble();
    return CardSaleResult(
      cardName: name.trim(),
      referencePrice: price,
      discountPercent: discount,
      finalValue: price * (1 - discount / 100),
    );
  }
}

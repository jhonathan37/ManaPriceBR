class PriceResult {
  const PriceResult({
    required this.cardName,
    required this.referencePrice,
    required this.discountPercent,
    required this.salePrice,
    this.currency = 'BRL',
  });

  final String cardName;
  final double referencePrice;
  final double discountPercent;
  final double salePrice;
  final String currency;

  double get discountAmount => referencePrice - salePrice;
}

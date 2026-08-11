class CardSaleResult {
  const CardSaleResult({
    required this.cardName,
    required this.referencePrice,
    required this.discountPercent,
    required this.finalValue,
  });

  final String cardName;
  final double referencePrice;
  final double discountPercent;
  final double finalValue;

  double get discountAmount => referencePrice - finalValue;
}

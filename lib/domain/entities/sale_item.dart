class SaleItem {
  const SaleItem({
    required this.cardName,
    required this.referencePrice,
    required this.discountPercent,
    this.imageUrl,
    this.priceAvailable = true,
    this.sourceName,
  });

  final String cardName;
  final double referencePrice;
  final double discountPercent;
  final String? imageUrl;
  final bool priceAvailable;
  final String? sourceName;

  double get finalValue => priceAvailable
      ? referencePrice * (1 - discountPercent.clamp(0, 100) / 100)
      : 0;
}

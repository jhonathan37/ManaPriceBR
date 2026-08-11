class SaleItem {
  const SaleItem({
    required this.cardName,
    required this.referencePrice,
    required this.discountPercent,
    this.imageUrl,
  });

  final String cardName;
  final double referencePrice;
  final double discountPercent;
  final String? imageUrl;

  double get finalValue =>
      referencePrice * (1 - discountPercent.clamp(0, 100) / 100);
}

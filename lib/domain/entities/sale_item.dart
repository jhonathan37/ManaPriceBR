class SaleItem {
  const SaleItem({
    required this.cardName,
    required this.referencePrice,
    required this.discountPercent,
    this.displayName,
    this.imageUrl,
    this.priceAvailable = true,
    this.sourceName,
    this.editionCode,
    this.averagePrice,
    this.maximumPrice,
    this.priceVerified = false,
  });

  final String cardName;
  final String? displayName;
  final double referencePrice;
  final double discountPercent;
  final String? imageUrl;
  final bool priceAvailable;
  final String? sourceName;
  final String? editionCode;
  final double? averagePrice;
  final double? maximumPrice;
  final bool priceVerified;

  String get visibleName =>
      displayName != null && displayName!.trim().isNotEmpty
          ? displayName!.trim()
          : cardName;

  double get finalValue => priceAvailable
      ? referencePrice * (1 - discountPercent.clamp(0, 100) / 100)
      : 0;
}

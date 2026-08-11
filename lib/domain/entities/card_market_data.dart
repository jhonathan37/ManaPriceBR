class CardMarketData {
  const CardMarketData({
    required this.cardName,
    required this.referencePrice,
    this.minimumPrice,
    this.maximumPrice,
    this.imageUrl,
    this.source = 'Liga Magic',
  });

  final String cardName;
  final double referencePrice;
  final double? minimumPrice;
  final double? maximumPrice;
  final String? imageUrl;
  final String source;

  bool get hasImage => imageUrl != null && imageUrl!.trim().isNotEmpty;
}

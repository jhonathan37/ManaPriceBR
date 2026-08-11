class LigaMagicScrapeResult {
  const LigaMagicScrapeResult({
    required this.cardName,
    required this.referencePrice,
    this.imageUrl,
    this.sourceUrl,
  });

  final String cardName;
  final double referencePrice;
  final String? imageUrl;
  final String? sourceUrl;
}

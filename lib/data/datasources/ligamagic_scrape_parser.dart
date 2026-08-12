import 'price_source.dart';

class LigaMagicScrapeResult {
  const LigaMagicScrapeResult({
    required this.response,
    required this.imageUrl,
  });

  final PriceLookupResponse response;
  final String? imageUrl;
}

/// Conservative HTML parser for LigaMagic responses.
/// It intentionally only accepts prices that are close to the requested card
/// name and rejects pages without a plausible card/price match.
class LigaMagicScrapeParser {
  const LigaMagicScrapeParser._();

  static LigaMagicScrapeResult? parse({
    required String cardName,
    required String html,
  }) {
    final normalizedHtml = html.replaceAll(RegExp(r'\s+'), ' ');
    final escapedName = RegExp.escape(cardName.trim());
    final cardPattern = RegExp(
      '(.{0,800}$escapedName.{0,1800})',
      caseSensitive: false,
      dotAll: true,
    );
    final cardMatch = cardPattern.firstMatch(normalizedHtml);
    if (cardMatch == null) return null;

    final block = cardMatch.group(1)!;
    final priceMatches = RegExp(
      r'R\$\s*([0-9]{1,6}(?:\.[0-9]{3})*,[0-9]{2}|[0-9]+(?:\.[0-9]{2}))',
    ).allMatches(block);

    final prices = <double>[];
    for (final match in priceMatches) {
      final raw = match.group(1);
      if (raw == null) continue;
      final normalized = raw.contains(',')
          ? raw.replaceAll('.', '').replaceAll(',', '.')
          : raw;
      final value = double.tryParse(normalized);
      if (value != null && value > 0) prices.add(value);
    }
    if (prices.isEmpty) return null;

    prices.sort();
    final imageMatch = RegExp(
      r"<img[^>]+(?:src|data-src)=[\"']([^\"']+)[\"'][^>]*>",
      caseSensitive: false,
    ).firstMatch(block);

    return LigaMagicScrapeResult(
      response: PriceLookupResponse(
        cardName: cardName,
        referencePrice: prices.first,
        sourceName: 'Liga Magic',
      ),
      imageUrl: imageMatch?.group(1),
    );
  }
}

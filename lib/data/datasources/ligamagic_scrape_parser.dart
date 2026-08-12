import 'price_source.dart';

class LigaMagicScrapeResult {
  const LigaMagicScrapeResult({
    required this.response,
    required this.imageUrl,
  });

  final PriceLookupResponse response;
  final String? imageUrl;
}

class LigaMagicScrapeParser {
  const LigaMagicScrapeParser._();

  static LigaMagicScrapeResult? parse({
    required PriceLookupRequest request,
    required String html,
  }) {
    final normalizedHtml = html.replaceAll(RegExp(r'\s+'), ' ');
    final escapedName = RegExp.escape(request.cardName.trim());

    final blocks = RegExp(
      '(.{0,1200}$escapedName.{0,3200})',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(normalizedHtml);

    final prices = <double>[];
    String? imageUrl;

    for (final match in blocks) {
      final block = match.group(1);
      if (block == null) continue;
      prices.addAll(_extractPrices(block));

      imageUrl ??= RegExp(
        r'<img[^>]+(?:src|data-src)="([^"]+)"[^>]*>',
        caseSensitive: false,
      ).firstMatch(block)?.group(1);
    }

    if (prices.isEmpty) return null;
    prices.sort();

    return LigaMagicScrapeResult(
      response: PriceLookupResponse(
        cardName: request.cardName,
        referencePrice: prices.first,
        sourceName: 'Liga Magic',
      ),
      imageUrl: imageUrl,
    );
  }

  static List<double> _extractPrices(String block) {
    final prices = <double>[];
    final matches = RegExp(
      r'R\$\s*([0-9]{1,6}(?:\.[0-9]{3})*,[0-9]{2}|[0-9]+(?:\.[0-9]{2}))',
    ).allMatches(block);

    for (final match in matches) {
      final raw = match.group(1);
      if (raw == null) continue;
      final normalized = raw.contains(',')
          ? raw.replaceAll('.', '').replaceAll(',', '.')
          : raw;
      final value = double.tryParse(normalized);
      if (value != null && value > 0) prices.add(value);
    }
    return prices;
  }
}

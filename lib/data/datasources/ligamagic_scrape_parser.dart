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
    final nameMatches = RegExp(
      escapedName,
      caseSensitive: false,
    ).allMatches(normalizedHtml);

    final prices = <double>[];
    String? imageUrl;

    for (final nameMatch in nameMatches) {
      final block = _blockAfterCardName(normalizedHtml, nameMatch.end);
      if (block.isEmpty) continue;

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

  static String _blockAfterCardName(String html, int start) {
    final maxEnd = (start + 2400).clamp(0, html.length);
    final tail = html.substring(start, maxEnd);

    // Prefer semantic/container boundaries so a cheaper price from a previous
    // or following card does not contaminate the requested card's result.
    final boundaryPatterns = <RegExp>[
      RegExp(r'</section\s*>', caseSensitive: false),
      RegExp(r'</article\s*>', caseSensitive: false),
      RegExp(r'</li\s*>', caseSensitive: false),
      RegExp(r'</tr\s*>', caseSensitive: false),
      RegExp(r'<h[1-4][^>]*>', caseSensitive: false),
    ];

    int? boundary;
    for (final pattern in boundaryPatterns) {
      final match = pattern.firstMatch(tail);
      if (match == null || match.start == 0) continue;
      if (boundary == null || match.start < boundary) boundary = match.start;
    }

    return boundary == null ? tail : tail.substring(0, boundary);
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

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
    final matches = RegExp(
      '(.{0,1000}$escapedName.{0,2600})',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(normalizedHtml);

    String? block;
    for (final match in matches) {
      final candidate = match.group(1);
      if (candidate == null) continue;
      if (!_matchesPrinting(candidate, request)) continue;
      if (!_matchesFinish(candidate, request.foil)) continue;
      if (!_matchesCondition(candidate, request.condition)) continue;
      if (!_matchesLanguage(candidate, request.language)) continue;
      block = candidate;
      break;
    }
    if (block == null) return null;

    final prices = _extractPrices(block);
    if (prices.isEmpty) return null;
    prices.sort();

    final imageMatch = RegExp(
      r'<img[^>]+(?:src|data-src)="([^"]+)"[^>]*>',
      caseSensitive: false,
    ).firstMatch(block);

    return LigaMagicScrapeResult(
      response: PriceLookupResponse(
        cardName: request.cardName,
        referencePrice: prices.first,
        sourceName: 'Liga Magic',
      ),
      imageUrl: imageMatch?.group(1),
    );
  }

  static bool _matchesPrinting(String block, PriceLookupRequest request) {
    if (!request.hasExactPrinting) return false;
    final lower = block.toLowerCase();
    final setCode = request.setCode!.toLowerCase();
    final collector = request.collectorNumber!.toLowerCase();
    final setName = request.setName?.toLowerCase();

    final hasCollector = lower.contains(collector);
    final hasEdition = lower.contains(setCode) ||
        (setName != null && setName.isNotEmpty && lower.contains(setName));
    return hasCollector && hasEdition;
  }

  static bool _matchesFinish(String block, bool foil) {
    final lower = block.toLowerCase();
    final mentionsFoil = lower.contains('foil');
    return foil ? mentionsFoil : !mentionsFoil || lower.contains('non-foil') || lower.contains('nonfoil');
  }

  static bool _matchesCondition(String block, String condition) {
    final lower = block.toLowerCase();
    final c = condition.toLowerCase();
    final aliases = <String, List<String>>{
      'nm': ['nm', 'near mint'],
      'sp': ['sp', 'slightly played'],
      'mp': ['mp', 'moderately played'],
      'hp': ['hp', 'heavily played'],
    };
    return (aliases[c] ?? [c]).any(lower.contains);
  }

  static bool _matchesLanguage(String block, String language) {
    final lower = block.toLowerCase();
    final l = language.toLowerCase();
    final aliases = <String, List<String>>{
      'português': ['português', 'portugues', 'pt-br', 'pt'],
      'inglês': ['inglês', 'ingles', 'english', 'en'],
      'espanhol': ['espanhol', 'spanish', 'es'],
    };
    return (aliases[l] ?? [l]).any(lower.contains);
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

import 'dart:convert';

import 'price_source.dart';

class LigaMagicScrapeResult {
  const LigaMagicScrapeResult({
    required this.response,
    required this.imageUrl,
    required this.visuallyVerified,
    this.editionCode,
    this.averagePrice,
    this.maximumPrice,
  });

  final PriceLookupResponse response;
  final String? imageUrl;
  final bool visuallyVerified;
  final String? editionCode;
  final double? averagePrice;
  final double? maximumPrice;
}

class LigaMagicScrapeParser {
  const LigaMagicScrapeParser._();

  static LigaMagicScrapeResult? parse({
    required PriceLookupRequest request,
    required String html,
  }) {
    // Primary source: LigaMagic's own structured edition data.
    // This is more reliable than scanning arbitrary BRL values from the page.
    final editionsResult = _parseCardsEditions(request: request, html: html);
    if (editionsResult != null) return editionsResult;

    // Fallback: visible marketplace offer, mainly useful when the structured
    // data is absent or cannot represent the requested variant (e.g. foil).
    final visible = _parseVisibleHtml(request: request, html: html);
    if (visible != null) return visible;

    // Legacy cardsjson is intentionally unverified. It is kept only as a final
    // hint for older pages and must never be treated as a trusted final price.
    final structuredPrices = List<double>.of(
      _extractCardsJsonMinimumPrices(html, request.cardName),
    )..sort();
    final structured = structuredPrices.isEmpty ? null : structuredPrices.first;
    if (structured == null) return null;

    return LigaMagicScrapeResult(
      response: PriceLookupResponse(
        cardName: request.cardName,
        referencePrice: structured,
        sourceName: 'Liga Magic',
      ),
      imageUrl: _extractImage(html),
      visuallyVerified: false,
    );
  }

  static LigaMagicScrapeResult? _parseCardsEditions({
    required PriceLookupRequest request,
    required String html,
  }) {
    // The public Liga price extension and Liga pages expose:
    //   var cards_editions = [ ... ];
    final rawArray = _extractJsonArray(html, 'cards_editions');
    if (rawArray == null) return null;

    dynamic decoded;
    try {
      decoded = jsonDecode(_stripJsonComments(rawArray));
    } catch (_) {
      return null;
    }
    if (decoded is! List) return null;

    final wantedSet = request.setCode?.trim().toUpperCase();
    final candidates = <_EditionPrice>[];

    for (final item in decoded) {
      if (item is! Map) continue;
      final code = '${item['code'] ?? ''}'.trim().toUpperCase();
      if (wantedSet != null && wantedSet.isNotEmpty && code != wantedSet) {
        continue;
      }

      final priceData = item['price'];
      final entry = _selectStructuredPriceEntry(priceData, request.foil);
      if (entry == null) continue;

      final minimum = _toPrice(entry['p']);
      final average = _toPrice(entry['m']);
      final maximum = _toPrice(entry['g']);
      if ((minimum ?? 0) <= 0 && (average ?? 0) <= 0 && (maximum ?? 0) <= 0) {
        continue;
      }

      candidates.add(
        _EditionPrice(
          code: code.isEmpty ? null : code,
          minimum: minimum,
          average: average,
          maximum: maximum,
        ),
      );
    }

    if (candidates.isEmpty) return null;

    // When no edition was requested, use the lowest valid Liga minimum across
    // the available editions. With an exact edition, only matching candidates
    // reached this point.
    candidates.sort((a, b) {
      final av = a.minimum ?? a.average ?? a.maximum ?? double.infinity;
      final bv = b.minimum ?? b.average ?? b.maximum ?? double.infinity;
      return av.compareTo(bv);
    });
    final chosen = candidates.first;
    final reference = chosen.minimum ?? chosen.average ?? chosen.maximum;
    if (reference == null || reference <= 0) return null;

    return LigaMagicScrapeResult(
      response: PriceLookupResponse(
        cardName: request.cardName,
        referencePrice: reference,
        sourceName: 'Liga Magic',
      ),
      imageUrl: _extractImage(html),
      visuallyVerified: true,
      editionCode: chosen.code,
      averagePrice: chosen.average,
      maximumPrice: chosen.maximum,
    );
  }

  static Map<dynamic, dynamic>? _selectStructuredPriceEntry(
    dynamic priceData,
    bool foil,
  ) {
    if (priceData == null) return null;

    final entries = <Map<dynamic, dynamic>>[];
    if (priceData is List) {
      for (final item in priceData) {
        if (item is Map) entries.add(item);
      }
    } else if (priceData is Map) {
      final numericKeys = priceData.keys.toList()
        ..sort((a, b) => '$a'.compareTo('$b'));
      for (final key in numericKeys) {
        final item = priceData[key];
        if (item is Map) entries.add(item);
      }
    }
    if (entries.isEmpty) return null;

    bool looksFoil(Map<dynamic, dynamic> entry) {
      final text = entry.entries
          .map((e) => '${e.key}:${e.value}')
          .join(' ')
          .toLowerCase();
      return text.contains('foil') &&
          !text.contains('nonfoil') &&
          !text.contains('non-foil') &&
          !text.contains('não foil') &&
          !text.contains('nao foil');
    }

    if (foil) {
      for (final entry in entries) {
        if (looksFoil(entry)) return entry;
      }
      // Do not assume that index 1 means foil. If Liga doesn't identify it,
      // let the caller fall back to the browser/visible offer path.
      return null;
    }

    for (final entry in entries) {
      if (!looksFoil(entry)) return entry;
    }
    return entries.first;
  }

  static LigaMagicScrapeResult? _parseVisibleHtml({
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
      final block = _containingOfferBlock(
        normalizedHtml,
        nameMatch.start,
        nameMatch.end,
      );
      if (block.isEmpty || !_matchesFilters(block, request)) continue;
      prices.addAll(_extractVisiblePrices(block));
      imageUrl ??= _extractImage(block);
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
      visuallyVerified: true,
    );
  }

  static bool _matchesFilters(String block, PriceLookupRequest request) {
    final text = _plain(block).toLowerCase();
    if (request.setName != null && request.setName!.trim().isNotEmpty) {
      if (!text.contains(request.setName!.trim().toLowerCase())) return false;
    }
    if (request.collectorNumber != null && request.collectorNumber!.trim().isNotEmpty) {
      final number = request.collectorNumber!.trim().toLowerCase();
      if (!text.contains(number)) return false;
    }
    final condition = request.condition.trim().toLowerCase();
    if (condition.isNotEmpty &&
        RegExp(r'\b(nm|sp|mp|hp|dmg|damaged)\b').hasMatch(text)) {
      if (!RegExp('\\b${RegExp.escape(condition)}\\b').hasMatch(text)) {
        return false;
      }
    }
    final hasFoilMarker = RegExp(r'\bfoil\b', caseSensitive: false).hasMatch(text);
    final explicitlyNonFoil = RegExp(
      r'\b(non[- ]?foil|nao foil|não foil)\b',
      caseSensitive: false,
    ).hasMatch(text);
    if (request.foil && !hasFoilMarker) return false;
    if (!request.foil && hasFoilMarker && !explicitlyNonFoil) return false;
    return true;
  }

  static String _containingOfferBlock(String html, int nameStart, int nameEnd) {
    const tags = ['tr', 'li', 'article', 'section'];
    for (final tag in tags) {
      final open = html.lastIndexOf('<$tag', nameStart);
      if (open < 0) continue;
      final close = html.indexOf('</$tag>', nameEnd);
      if (close < 0) continue;
      final end = close + tag.length + 3;
      if (end - open <= 6000) return html.substring(open, end);
    }
    final start = (nameStart - 300).clamp(0, html.length);
    final end = (nameEnd + 700).clamp(0, html.length);
    return html.substring(start, end);
  }

  static String _plain(String html) => html
      .replaceAll(
        RegExp(r'<script\b[^>]*>.*?</script>', caseSensitive: false),
        ' ',
      )
      .replaceAll(
        RegExp(r'<style\b[^>]*>.*?</style>', caseSensitive: false),
        ' ',
      )
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static List<double> _extractCardsJsonMinimumPrices(
    String html,
    String cardName,
  ) {
    final rawArray = _extractJsonArray(html, 'cardsjson');
    if (rawArray == null) return const [];
    dynamic decoded;
    try {
      decoded = jsonDecode(rawArray);
    } catch (_) {
      return const [];
    }
    if (decoded is! List) return const [];
    final target = _baseName(cardName).toLowerCase();
    final prices = <double>[];
    for (final item in decoded) {
      if (item is! Map) continue;
      final enName = _baseName('${item['nEN'] ?? ''}').toLowerCase();
      final ptName = _baseName('${item['nPT'] ?? ''}').toLowerCase();
      if (enName != target && ptName != target) continue;
      final minimum = _toPrice(item['p1a']);
      if (minimum != null && minimum > 0) prices.add(minimum);
    }
    return prices;
  }

  static String? _extractJsonArray(String html, String variableName) {
    final startPattern = RegExp(
      'var\\s+${RegExp.escape(variableName)}\\s*=\\s*\\[',
      caseSensitive: false,
    );
    final startMatch = startPattern.firstMatch(html);
    if (startMatch == null) return null;
    final start = startMatch.end - 1;
    var depth = 0;
    var inString = false;
    var quote = '';
    var escaped = false;
    for (var i = start; i < html.length; i++) {
      final char = html[i];
      if (inString) {
        if (escaped) {
          escaped = false;
          continue;
        }
        if (char == r'\') {
          escaped = true;
          continue;
        }
        if (char == quote) inString = false;
        continue;
      }
      if (char == '"' || char == "'") {
        inString = true;
        quote = char;
      } else if (char == '[') {
        depth++;
      } else if (char == ']') {
        depth--;
        if (depth == 0) return html.substring(start, i + 1);
      }
    }
    return null;
  }

  static String _stripJsonComments(String value) => value
      .replaceAll(RegExp(r'//.*$', multiLine: true), '')
      .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');

  static double? _toPrice(dynamic raw) {
    if (raw is num) return raw.toDouble();
    if (raw == null) return null;
    var value = raw.toString().trim().replaceAll('R\$', '').trim();
    if (value.isEmpty || value == '-' || value == '0') return null;
    if (value.contains(',')) {
      value = value.replaceAll('.', '').replaceAll(',', '.');
    } else if (RegExp(r'^\d{1,3}(?:\.\d{3})+$').hasMatch(value)) {
      value = value.replaceAll('.', '');
    }
    return double.tryParse(value);
  }

  static String _baseName(String value) => value
      .replaceAll(RegExp(r'\s*\([^()]*\)\s*$'), '')
      .split(' // ')
      .first
      .trim();

  static List<double> _extractVisiblePrices(String block) {
    final prices = <double>[];
    final matches = RegExp(
      r'R\$\s*((?:\d{1,3}(?:\.\d{3})+|\d+)(?:,\d{2})?)',
    ).allMatches(block);
    for (final match in matches) {
      final value = _toPrice(match.group(1));
      if (value != null && value > 0) prices.add(value);
    }
    return prices;
  }

  static String? _extractImage(String html) => RegExp(
        r'<img[^>]+(?:src|data-src)="([^"]+)"[^>]*>',
        caseSensitive: false,
      ).firstMatch(html)?.group(1);
}

class _EditionPrice {
  const _EditionPrice({
    required this.code,
    required this.minimum,
    required this.average,
    required this.maximum,
  });

  final String? code;
  final double? minimum;
  final double? average;
  final double? maximum;
}

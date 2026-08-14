import 'dart:convert';

import 'price_source.dart';

class LigaMagicScrapeResult {
  const LigaMagicScrapeResult({
    required this.response,
    required this.imageUrl,
    required this.visuallyVerified,
  });

  final PriceLookupResponse response;
  final String? imageUrl;
  final bool visuallyVerified;
}

class LigaMagicScrapeParser {
  const LigaMagicScrapeParser._();

  static LigaMagicScrapeResult? parse({
    required PriceLookupRequest request,
    required String html,
  }) {
    final structuredPrices = List<double>.of(
      _extractCardsJsonMinimumPrices(html, request.cardName),
    )..sort();
    final visible = _parseVisibleHtml(request: request, html: html);
    final structured = structuredPrices.isEmpty ? null : structuredPrices.first;

    if (visible == null) {
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

    // A visible marketplace offer is authoritative. cardsjson is catalog metadata
    // and may contain stale/scaled values (e.g. 4.95 while the offer is 495.00).
    return visible;
  }

  static LigaMagicScrapeResult? _parseVisibleHtml({
    required PriceLookupRequest request,
    required String html,
  }) {
    final normalizedHtml = html.replaceAll(RegExp(r'\s+'), ' ');
    final escapedName = RegExp.escape(request.cardName.trim());
    final nameMatches = RegExp(escapedName, caseSensitive: false).allMatches(normalizedHtml);
    final prices = <double>[];
    String? imageUrl;

    for (final nameMatch in nameMatches) {
      final block = _containingOfferBlock(normalizedHtml, nameMatch.start, nameMatch.end);
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
    if (condition.isNotEmpty && RegExp(r'\b(nm|sp|mp|hp|dmg|damaged)\b').hasMatch(text)) {
      if (!RegExp('\\b${RegExp.escape(condition)}\\b').hasMatch(text)) return false;
    }
    final hasFoilMarker = RegExp(r'\bfoil\b', caseSensitive: false).hasMatch(text);
    final explicitlyNonFoil = RegExp(r'\b(non[- ]?foil|nao foil|não foil)\b', caseSensitive: false).hasMatch(text);
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
    // Never scan thousands of characters after a name. A small local window is
    // safer than accepting unrelated prices from another product/offer.
    final start = (nameStart - 300).clamp(0, html.length);
    final end = (nameEnd + 700).clamp(0, html.length);
    return html.substring(start, end);
  }

  static String _plain(String html) => html
      .replaceAll(RegExp(r'<script\b[^>]*>.*?</script>', caseSensitive: false), ' ')
      .replaceAll(RegExp(r'<style\b[^>]*>.*?</style>', caseSensitive: false), ' ')
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static List<double> _extractCardsJsonMinimumPrices(String html, String cardName) {
    final rawArray = _extractJsonArray(html, 'cardsjson');
    if (rawArray == null) return const [];
    dynamic decoded;
    try { decoded = jsonDecode(rawArray); } catch (_) { return const []; }
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
    final startPattern = RegExp('var\\s+${RegExp.escape(variableName)}\\s*=\\s*\\[', caseSensitive: false);
    final startMatch = startPattern.firstMatch(html);
    if (startMatch == null) return null;
    final start = startMatch.end - 1;
    var depth = 0; var inString = false; var quote = ''; var escaped = false;
    for (var i = start; i < html.length; i++) {
      final char = html[i];
      if (inString) {
        if (escaped) { escaped = false; continue; }
        if (char == r'\') { escaped = true; continue; }
        if (char == quote) inString = false;
        continue;
      }
      if (char == '"' || char == "'") { inString = true; quote = char; }
      else if (char == '[') { depth++; }
      else if (char == ']') { depth--; if (depth == 0) return html.substring(start, i + 1); }
    }
    return null;
  }

  static double? _toPrice(dynamic raw) {
    if (raw is num) return raw.toDouble();
    if (raw == null) return null;
    var value = raw.toString().trim().replaceAll('R\$', '').trim();
    if (value.isEmpty || value == '-' || value == '0') return null;
    if (value.contains(',')) value = value.replaceAll('.', '').replaceAll(',', '.');
    else if (RegExp(r'^\d{1,3}(?:\.\d{3})+$').hasMatch(value)) value = value.replaceAll('.', '');
    return double.tryParse(value);
  }

  static String _baseName(String value) => value.replaceAll(RegExp(r'\s*\([^()]*\)\s*$'), '').split(' // ').first.trim();

  static List<double> _extractVisiblePrices(String block) {
    final prices = <double>[];
    final matches = RegExp(r'R\$\s*((?:\d{1,3}(?:\.\d{3})+|\d+)(?:,\d{2})?)').allMatches(block);
    for (final match in matches) {
      final value = _toPrice(match.group(1));
      if (value != null && value > 0) prices.add(value);
    }
    return prices;
  }

  static String? _extractImage(String html) => RegExp(r'<img[^>]+(?:src|data-src)="([^"]+)"[^>]*>', caseSensitive: false).firstMatch(html)?.group(1);
}

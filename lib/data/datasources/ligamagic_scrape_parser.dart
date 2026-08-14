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

    if (structured == null) return visible;

    if (visible == null) {
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

    final visiblePrice = visible.response.referencePrice;
    final chosen = _reconcilePrices(structured, visiblePrice);

    return LigaMagicScrapeResult(
      response: PriceLookupResponse(
        cardName: request.cardName,
        referencePrice: chosen,
        sourceName: 'Liga Magic',
      ),
      imageUrl: visible.imageUrl ?? _extractImage(html),
      visuallyVerified: true,
    );
  }

  static double _reconcilePrices(double structured, double visible) {
    if (structured <= 0) return visible;
    if (visible <= 0) return structured;

    final larger = structured > visible ? structured : visible;
    final smaller = structured < visible ? structured : visible;
    final ratio = larger / smaller;

    if (ratio >= 10) return visible;

    return smaller;
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
      final block = _blockAfterCardName(normalizedHtml, nameMatch.end);
      if (block.isEmpty) continue;

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

  static String _blockAfterCardName(String html, int start) {
    final maxEnd = (start + 2400).clamp(0, html.length);
    final tail = html.substring(start, maxEnd);
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

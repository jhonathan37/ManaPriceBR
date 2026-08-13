import 'dart:async';

import 'package:dio/dio.dart';

import 'ligamagic_scrape_parser.dart';
import 'ligamagic_url_builder.dart';
import 'price_source.dart';

class LigaMagicScrapeClient {
  LigaMagicScrapeClient({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<LigaMagicScrapeResult?> lookup(PriceLookupRequest request) async {
    final direct = await _fetchAndParse(
      request,
      LigaMagicUrlBuilder.card(request),
    );
    if (direct != null) return direct;

    final searchHtml = await _fetchHtml(LigaMagicUrlBuilder.search(request));
    if (searchHtml == null) return null;

    final parsedFromSearch = LigaMagicScrapeParser.parse(
      request: request,
      html: searchHtml,
    );
    if (parsedFromSearch != null) return parsedFromSearch;

    final cardUri = _findCardPageUri(searchHtml, request.cardName);
    if (cardUri == null) return null;

    return _fetchAndParse(request, cardUri);
  }

  Future<LigaMagicScrapeResult?> _fetchAndParse(
    PriceLookupRequest request,
    Uri uri,
  ) async {
    final body = await _fetchHtml(uri);
    if (body == null) return null;

    return LigaMagicScrapeParser.parse(
      request: request,
      html: body,
    );
  }

  Future<String?> _fetchHtml(Uri uri) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await _dio.getUri<String>(
          uri,
          options: Options(
            responseType: ResponseType.plain,
            headers: {
              'Accept':
                  'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
              'Accept-Language': 'pt-BR,pt;q=0.9,en-US;q=0.8,en;q=0.7',
              'Cache-Control': 'no-cache',
              'Pragma': 'no-cache',
              'Referer': 'https://www.ligamagic.com.br/',
              'Upgrade-Insecure-Requests': '1',
              'Sec-Fetch-Dest': 'document',
              'Sec-Fetch-Mode': 'navigate',
              'Sec-Fetch-Site': 'same-origin',
              'User-Agent':
                  'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 '
                  '(KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36',
            },
            sendTimeout: const Duration(seconds: 12),
            receiveTimeout: const Duration(seconds: 15),
            followRedirects: true,
            validateStatus: (status) => status != null && status < 500,
          ),
        );

        if (response.statusCode == 200) {
          final body = response.data;
          if (body == null || body.isEmpty) return null;
          return body;
        }

        final retryable = response.statusCode == 403 || response.statusCode == 429;
        if (!retryable || attempt == 1) return null;
      } on DioException catch (error) {
        final retryable = error.type == DioExceptionType.connectionError ||
            error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.sendTimeout;
        if (!retryable || attempt == 1) return null;
      }

      await Future<void>.delayed(const Duration(milliseconds: 450));
    }

    return null;
  }

  static Uri? _findCardPageUri(String html, String cardName) {
    final target = _frontFace(cardName).toLowerCase();
    final linkPattern = RegExp(
      r'href="([^"]*\?view=cards/card&amp;card=[^"]+|[^"]*\?view=cards/card&card=[^"]+)"',
      caseSensitive: false,
    );

    Uri? firstCardUri;
    for (final match in linkPattern.allMatches(html)) {
      final rawHref = match.group(1);
      if (rawHref == null) continue;

      final decodedHref = rawHref.replaceAll('&amp;', '&');
      final absolute = decodedHref.startsWith('http')
          ? decodedHref
          : 'https://www.ligamagic.com.br/${decodedHref.startsWith('/') ? decodedHref.substring(1) : decodedHref}';
      final uri = Uri.tryParse(absolute);
      if (uri == null) continue;
      firstCardUri ??= uri;

      final candidate = uri.queryParameters['card'];
      if (candidate == null) continue;
      if (_frontFace(candidate).toLowerCase() == target) return uri;
    }

    return firstCardUri;
  }

  static String _frontFace(String name) {
    final index = name.indexOf(' // ');
    return (index >= 0 ? name.substring(0, index) : name).trim();
  }
}

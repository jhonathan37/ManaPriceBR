import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'ligamagic_scrape_parser.dart';
import 'ligamagic_url_builder.dart';
import 'price_source.dart';

class LigaMagicBrowserClient {
  const LigaMagicBrowserClient();

  Future<LigaMagicScrapeResult?> lookup(PriceLookupRequest request) async {
    if (kIsWeb) return null;

    final directHtml = await _loadHtml(LigaMagicUrlBuilder.card(request));
    final direct = _parse(request, directHtml);
    if (direct?.visuallyVerified == true) return direct;

    final searchHtml = await _loadHtml(LigaMagicUrlBuilder.search(request));
    final parsedSearch = _parse(request, searchHtml);
    if (parsedSearch?.visuallyVerified == true) return parsedSearch;

    final cardUri = _findCardPageUri(searchHtml, request.cardName);
    if (cardUri == null) return null;

    final cardHtml = await _loadHtml(cardUri);
    final cardResult = _parse(request, cardHtml);
    return cardResult?.visuallyVerified == true ? cardResult : null;
  }

  LigaMagicScrapeResult? _parse(
    PriceLookupRequest request,
    String? html,
  ) {
    if (html == null || html.isEmpty) return null;
    return LigaMagicScrapeParser.parse(
      request: request,
      html: html,
    );
  }

  Future<String?> _loadHtml(Uri uri) async {
    final completer = Completer<String?>();
    HeadlessInAppWebView? webView;
    var completed = false;

    Future<void> finish(String? html) async {
      if (completed) return;
      completed = true;
      if (!completer.isCompleted) completer.complete(html);
    }

    try {
      webView = HeadlessInAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(uri.toString())),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          domStorageEnabled: true,
          cacheEnabled: true,
          transparentBackground: true,
          userAgent:
              'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 '
              '(KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36',
        ),
        onLoadStop: (controller, url) async {
          await Future<void>.delayed(const Duration(milliseconds: 1800));
          try {
            final html = await controller.getHtml();
            await finish(html);
          } catch (_) {
            await finish(null);
          }
        },
        onReceivedError: (controller, request, error) async {
          if (request.isForMainFrame ?? true) {
            await finish(null);
          }
        },
      );

      await webView.run();
      return await completer.future.timeout(
        const Duration(seconds: 24),
        onTimeout: () => null,
      );
    } catch (_) {
      return null;
    } finally {
      try {
        await webView?.dispose();
      } catch (_) {}
    }
  }

  static Uri? _findCardPageUri(String? html, String cardName) {
    if (html == null || html.isEmpty) return null;

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

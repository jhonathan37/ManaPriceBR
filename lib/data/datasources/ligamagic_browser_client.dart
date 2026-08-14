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

    final direct = await _loadAndParse(
      request,
      LigaMagicUrlBuilder.card(request),
    );
    if (direct != null) return direct;

    return _loadAndParse(
      request,
      LigaMagicUrlBuilder.search(request),
    );
  }

  Future<LigaMagicScrapeResult?> _loadAndParse(
    PriceLookupRequest request,
    Uri uri,
  ) async {
    final html = await _loadHtml(uri);
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
          // A LigaMagic monta parte dos resultados depois do load inicial.
          await Future<void>.delayed(const Duration(milliseconds: 900));
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
        const Duration(seconds: 22),
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
}

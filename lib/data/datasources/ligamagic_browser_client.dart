import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'ligamagic_scrape_parser.dart';
import 'ligamagic_url_builder.dart';
import 'price_source.dart';

class LigaMagicBrowserClient {
  const LigaMagicBrowserClient();

  Future<LigaMagicScrapeResult?> lookup(PriceLookupRequest request) async {
    if (kIsWeb) return null;

    final directHtml = await _loadHtml(LigaMagicUrlBuilder.card(request), request);
    final direct = _parse(request, directHtml);
    if (direct?.visuallyVerified == true) return direct;

    final searchHtml = await _loadHtml(LigaMagicUrlBuilder.search(request), request);
    final parsedSearch = _parse(request, searchHtml);
    if (parsedSearch?.visuallyVerified == true) return parsedSearch;

    final cardUri = _findCardPageUri(searchHtml, request.cardName);
    if (cardUri == null) return null;

    final cardHtml = await _loadHtml(cardUri, request);
    final cardResult = _parse(request, cardHtml);
    return cardResult?.visuallyVerified == true ? cardResult : null;
  }

  LigaMagicScrapeResult? _parse(
    PriceLookupRequest request,
    String? html,
  ) {
    if (html == null || html.isEmpty) return null;
    return LigaMagicScrapeParser.parse(request: request, html: html);
  }

  Future<String?> _loadHtml(Uri uri, PriceLookupRequest request) async {
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
          await Future<void>.delayed(const Duration(milliseconds: 900));
          try {
            await _applyFilters(controller, request);
            await Future<void>.delayed(const Duration(milliseconds: 900));
            final html = await controller.getHtml();
            await finish(html);
          } catch (_) {
            try {
              await finish(await controller.getHtml());
            } catch (_) {
              await finish(null);
            }
          }
        },
        onReceivedError: (controller, webRequest, error) async {
          if (webRequest.isForMainFrame ?? true) await finish(null);
        },
      );

      await webView.run();
      return await completer.future.timeout(
        const Duration(seconds: 20),
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

  Future<void> _applyFilters(
    InAppWebViewController controller,
    PriceLookupRequest request,
  ) async {
    final payload = jsonEncode({
      'name': request.cardName,
      'setCode': request.setCode ?? '',
      'setName': request.setName ?? '',
      'collectorNumber': request.collectorNumber ?? '',
      'condition': request.condition,
      'foil': request.foil,
      'language': request.language,
    });

    await controller.evaluateJavascript(source: '''
      (() => {
        const f = $payload;
        const norm = v => (v || '').toString().normalize('NFD')
          .replace(/[\\u0300-\\u036f]/g, '').toLowerCase().trim();
        const fire = el => {
          el.dispatchEvent(new Event('input', {bubbles:true}));
          el.dispatchEvent(new Event('change', {bubbles:true}));
        };
        const descriptor = el => norm([
          el.name, el.id, el.getAttribute('aria-label'),
          el.getAttribute('placeholder'),
          el.closest('label')?.innerText,
          el.parentElement?.innerText
        ].filter(Boolean).join(' '));
        const choose = (el, wanted) => {
          if (!wanted) return false;
          const w = norm(wanted);
          const options = [...(el.options || [])];
          const exact = options.find(o => norm(o.value) === w || norm(o.text) === w);
          const partial = options.find(o => norm(o.text).includes(w) || w.includes(norm(o.text)));
          const found = exact || partial;
          if (!found) return false;
          el.value = found.value; fire(el); return true;
        };

        for (const el of document.querySelectorAll('input,select')) {
          const d = descriptor(el);
          if (el.tagName === 'SELECT') {
            if (/edicao|edition|colecao|set/.test(d)) choose(el, f.setName) || choose(el, f.setCode);
            else if (/condicao|condition|estado/.test(d)) choose(el, f.condition);
            else if (/idioma|language/.test(d)) choose(el, f.language);
          } else {
            if (/collector|numero|number/.test(d) && f.collectorNumber) {
              el.value = f.collectorNumber; fire(el);
            }
            if (/foil/.test(d) && (el.type === 'checkbox' || el.type === 'radio')) {
              el.checked = !!f.foil; fire(el);
            }
          }
        }

        if (f.foil) {
          for (const label of document.querySelectorAll('label')) {
            if (norm(label.innerText).includes('foil')) {
              const input = label.querySelector('input') ||
                (label.htmlFor ? document.getElementById(label.htmlFor) : null);
              if (input && !input.checked) { input.checked = true; fire(input); }
            }
          }
        }
        return true;
      })();
    ''');
  }

  static Uri? _findCardPageUri(String? html, String cardName) {
    if (html == null || html.isEmpty) return null;

    final target = _frontFace(cardName).toLowerCase();
    final linkPattern = RegExp(
      r'href="([^"]*\\?view=cards/card&amp;card=[^"]+|[^"]*\\?view=cards/card&card=[^"]+)"',
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

import 'dart:async';

import '../../domain/entities/sale_item.dart';
import '../datasources/ligamagic_browser_client.dart';
import '../datasources/ligamagic_scrape_client.dart';
import '../datasources/price_source.dart';
import '../datasources/scryfall_catalog_client.dart';

class CardPriceProvider {
  CardPriceProvider({
    LigaMagicScrapeClient? client,
    LigaMagicBrowserClient? browserClient,
    ScryfallCatalogClient? catalogClient,
  })  : _client = client ?? LigaMagicScrapeClient(),
        _browserClient = browserClient ?? const LigaMagicBrowserClient(),
        _catalogClient = catalogClient ?? ScryfallCatalogClient();

  final LigaMagicScrapeClient _client;
  final LigaMagicBrowserClient _browserClient;
  final ScryfallCatalogClient _catalogClient;

  static const _catalogTimeout = Duration(seconds: 4);
  static const _httpLookupTimeout = Duration(seconds: 5);
  static const _browserLookupTimeout = Duration(seconds: 8);

  Future<SaleItem?> find(
    String cardName, {
    double discountPercent = 20,
    String? setCode,
    String? setName,
    String? collectorNumber,
    String? imageUrl,
    String language = 'Português',
    String condition = 'NM',
    bool foil = false,
  }) async {
    final normalized = cardName.trim();
    if (normalized.isEmpty) return null;

    // Resolve catalog metadata in parallel. It must never block the first
    // price attempt. This keeps the result screen responsive even when
    // Scryfall is slow or temporarily unavailable.
    final catalogFuture = _catalogClient
        .find(normalized)
        .timeout(_catalogTimeout)
        .catchError((_) => null);

    final typedRequest = PriceLookupRequest(
      cardName: normalized,
      setCode: setCode,
      setName: setName,
      collectorNumber: collectorNumber,
      language: language,
      condition: condition,
      foil: foil,
    );

    dynamic directResult;
    try {
      directResult = await _client.lookup(typedRequest).timeout(_httpLookupTimeout);
    } catch (_) {}

    final catalogCard = await catalogFuture;
    final canonicalName = catalogCard?.name ?? normalized;
    final displayName = _nonBlank(catalogCard?.displayName) ?? normalized;
    final catalogImage = _nonBlank(imageUrl) ?? _nonBlank(catalogCard?.imageUrl);

    if (directResult != null && directResult.response.referencePrice > 0) {
      return _toSaleItem(
        canonicalName,
        displayName,
        catalogImage,
        discountPercent,
        directResult,
      );
    }

    // Browser fallback uses the resolved canonical name when available, but
    // only after the fast direct lookup has already failed.
    final browserRequest = PriceLookupRequest(
      cardName: canonicalName,
      setCode: setCode,
      setName: setName,
      collectorNumber: collectorNumber,
      language: language,
      condition: condition,
      foil: foil,
    );

    try {
      final result = await _browserClient
          .lookup(browserRequest)
          .timeout(_browserLookupTimeout);
      if (result != null && result.response.referencePrice > 0) {
        return _toSaleItem(
          canonicalName,
          displayName,
          catalogImage,
          discountPercent,
          result,
        );
      }
    } catch (_) {}

    // Never trap the UI behind an endless spinner. Return the card metadata
    // even if the external price source did not answer this time.
    return SaleItem(
      cardName: canonicalName,
      displayName: displayName,
      referencePrice: 0,
      discountPercent: discountPercent,
      imageUrl: catalogImage,
      priceAvailable: false,
      sourceName: 'LigaMagic',
      priceVerified: false,
    );
  }

  SaleItem _toSaleItem(
    String canonicalName,
    String? displayName,
    String? catalogImage,
    double discountPercent,
    dynamic result,
  ) {
    return SaleItem(
      cardName: canonicalName,
      displayName: displayName,
      referencePrice: result.response.referencePrice,
      discountPercent: discountPercent,
      imageUrl: catalogImage ?? _nonBlank(result.imageUrl),
      priceAvailable: true,
      sourceName: result.response.sourceName,
      editionCode: result.editionCode,
      averagePrice: result.averagePrice,
      maximumPrice: result.maximumPrice,
      priceVerified: result.visuallyVerified == true,
    );
  }

  static String? _nonBlank(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

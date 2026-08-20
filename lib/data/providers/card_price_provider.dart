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

  static const _catalogTimeout = Duration(seconds: 5);
  static const _httpLookupTimeout = Duration(seconds: 6);
  static const _browserLookupTimeout = Duration(seconds: 20);

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

    String canonicalName = normalized;
    String? displayName = normalized;
    String? catalogImage = _nonBlank(imageUrl);

    try {
      final catalogCard = await _catalogClient
          .find(normalized)
          .timeout(_catalogTimeout);
      if (catalogCard != null) {
        canonicalName = catalogCard.name;
        displayName = _nonBlank(catalogCard.displayName) ?? normalized;
        catalogImage ??= _nonBlank(catalogCard.imageUrl);
      }
    } on TimeoutException {
      // Keep the typed name and continue. Price lookup must not be blocked by
      // a slow catalog request; the LigaMagic/browser path can still succeed.
    } catch (_) {}

    final request = PriceLookupRequest(
      cardName: canonicalName,
      setCode: setCode,
      setName: setName,
      collectorNumber: collectorNumber,
      language: language,
      condition: condition,
      foil: foil,
    );

    try {
      final result = await _client
          .lookup(request)
          .timeout(_httpLookupTimeout);
      if (result != null && result.response.referencePrice > 0) {
        return _toSaleItem(
          canonicalName,
          displayName,
          catalogImage,
          discountPercent,
          result,
        );
      }
    } on TimeoutException {
      // LigaMagic sometimes stalls/blocks direct HTTP. Move quickly to the
      // in-app browser instead of making the user wait through all retries.
    } catch (_) {}

    try {
      final result = await _browserClient
          .lookup(request)
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
    } on TimeoutException {
      // Return an explicit no-price result so the UI can offer "Tentar novamente".
    } catch (_) {}

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

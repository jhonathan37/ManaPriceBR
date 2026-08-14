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

  Future<SaleItem?> find(
    String cardName, {
    double discountPercent = 20,
  }) async {
    final normalized = cardName.trim();
    if (normalized.isEmpty) return null;

    String canonicalName = normalized;
    String? catalogImage;

    try {
      final catalogCard = await _catalogClient.find(normalized);
      if (catalogCard != null) {
        canonicalName = catalogCard.name;
        catalogImage = catalogCard.imageUrl;
      }
    } catch (_) {}

    final request = PriceLookupRequest(cardName: canonicalName);

    try {
      final result = await _client.lookup(request);
      if (result != null && result.response.referencePrice > 0) {
        return _toSaleItem(
          canonicalName,
          catalogImage,
          discountPercent,
          result,
        );
      }
    } catch (_) {}

    // A LigaMagic pode bloquear requests HTTP diretos (403/anti-bot).
    // No aparelho, tentamos novamente dentro de um WebView real, preservando
    // JavaScript, cookies e o mesmo contexto de navegação usado pelo site.
    try {
      final result = await _browserClient.lookup(request);
      if (result != null && result.response.referencePrice > 0) {
        return _toSaleItem(
          canonicalName,
          catalogImage,
          discountPercent,
          result,
        );
      }
    } catch (_) {}

    return SaleItem(
      cardName: canonicalName,
      referencePrice: 0,
      discountPercent: discountPercent,
      imageUrl: catalogImage,
      priceAvailable: false,
      sourceName: 'LigaMagic',
    );
  }

  SaleItem _toSaleItem(
    String canonicalName,
    String? catalogImage,
    double discountPercent,
    dynamic result,
  ) {
    return SaleItem(
      cardName: canonicalName,
      referencePrice: result.response.referencePrice,
      discountPercent: discountPercent,
      imageUrl: catalogImage ?? result.imageUrl,
      priceAvailable: true,
      sourceName: result.response.sourceName,
    );
  }
}

import '../../domain/entities/sale_item.dart';
import '../datasources/ligamagic_scrape_client.dart';
import '../datasources/price_source.dart';
import '../datasources/scryfall_catalog_client.dart';

class CardPriceProvider {
  CardPriceProvider({
    LigaMagicScrapeClient? client,
    ScryfallCatalogClient? catalogClient,
  })  : _client = client ?? LigaMagicScrapeClient(),
        _catalogClient = catalogClient ?? ScryfallCatalogClient();

  final LigaMagicScrapeClient _client;
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

    try {
      final result = await _client.lookup(
        PriceLookupRequest(cardName: canonicalName),
      );

      if (result != null) {
        return SaleItem(
          cardName: canonicalName,
          referencePrice: result.response.referencePrice,
          discountPercent: discountPercent,
          imageUrl: catalogImage ?? result.imageUrl,
          priceAvailable: true,
          sourceName: result.response.sourceName,
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
}

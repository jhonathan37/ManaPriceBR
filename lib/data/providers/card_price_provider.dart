import '../../domain/entities/sale_item.dart';
import '../datasources/ligamagic_scrape_client.dart';
import '../datasources/price_source.dart';
import '../datasources/scryfall_catalog_client.dart';
import 'demo_card_provider.dart';

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
    String language = 'Português',
    String condition = 'NM',
    bool foil = false,
    double discountPercent = 20,
    bool allowDemoFallback = true,
  }) async {
    final normalized = cardName.trim();
    if (normalized.isEmpty) return null;

    ScryfallCatalogCard? catalogCard;
    try {
      catalogCard = await _catalogClient.find(normalized);
    } catch (_) {
      // Catalog lookup is best effort. We can still try LigaMagic directly.
    }

    final canonicalName = catalogCard?.name ?? normalized;

    try {
      final result = await _client.lookup(
        PriceLookupRequest(
          cardName: canonicalName,
          language: language,
          condition: condition,
          foil: foil,
        ),
      );

      if (result != null) {
        return SaleItem(
          cardName: canonicalName,
          referencePrice: result.response.referencePrice,
          discountPercent: discountPercent,
          imageUrl: result.imageUrl ?? catalogCard?.imageUrl,
          priceAvailable: true,
          sourceName: result.response.sourceName,
        );
      }
    } catch (_) {
      // LigaMagic may throttle or block automated requests.
    }

    if (catalogCard != null) {
      return SaleItem(
        cardName: catalogCard.name,
        referencePrice: 0,
        discountPercent: discountPercent,
        imageUrl: catalogCard.imageUrl,
        priceAvailable: false,
        sourceName: 'Scryfall (catálogo)',
      );
    }

    if (!allowDemoFallback) return null;
    final demo = await DemoCardProvider.find(
      normalized,
      discountPercent: discountPercent,
    );
    if (demo == null) return null;
    return SaleItem(
      cardName: demo.cardName,
      referencePrice: demo.referencePrice,
      discountPercent: demo.discountPercent,
      imageUrl: demo.imageUrl,
      priceAvailable: true,
      sourceName: 'Catálogo local de teste',
    );
  }
}

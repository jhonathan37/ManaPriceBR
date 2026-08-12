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
    String? setCode,
    String? setName,
    String? collectorNumber,
    String language = 'Português',
    String condition = 'NM',
    bool foil = false,
    double discountPercent = 20,
  }) async {
    final normalized = cardName.trim();
    if (normalized.isEmpty ||
        setCode == null || setCode.isEmpty ||
        collectorNumber == null || collectorNumber.isEmpty) {
      return null;
    }

    String? printingImage;
    try {
      final printings = await _catalogClient.printings(normalized);
      for (final printing in printings) {
        if (printing.setCode.toLowerCase() == setCode.toLowerCase() &&
            printing.collectorNumber.toLowerCase() == collectorNumber.toLowerCase()) {
          printingImage = printing.imageUrl;
          break;
        }
      }
    } catch (_) {}

    try {
      final result = await _client.lookup(
        PriceLookupRequest(
          cardName: normalized,
          setCode: setCode,
          setName: setName,
          collectorNumber: collectorNumber,
          language: language,
          condition: condition,
          foil: foil,
        ),
      );

      if (result != null) {
        return SaleItem(
          cardName: normalized,
          referencePrice: result.response.referencePrice,
          discountPercent: discountPercent,
          imageUrl: printingImage ?? result.imageUrl,
          priceAvailable: true,
          sourceName: result.response.sourceName,
        );
      }
    } catch (_) {}

    return SaleItem(
      cardName: normalized,
      referencePrice: 0,
      discountPercent: discountPercent,
      imageUrl: printingImage,
      priceAvailable: false,
      sourceName: 'LigaMagic',
    );
  }
}

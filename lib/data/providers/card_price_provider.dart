import '../../domain/entities/sale_item.dart';
import '../datasources/ligamagic_scrape_client.dart';
import '../datasources/price_source.dart';
import 'demo_card_provider.dart';

class CardPriceProvider {
  CardPriceProvider({LigaMagicScrapeClient? client})
      : _client = client ?? LigaMagicScrapeClient();

  final LigaMagicScrapeClient _client;

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

    try {
      final result = await _client.lookup(
        PriceLookupRequest(
          cardName: normalized,
          language: language,
          condition: condition,
          foil: foil,
        ),
      );

      if (result != null) {
        return SaleItem(
          cardName: result.response.cardName,
          referencePrice: result.response.referencePrice,
          discountPercent: discountPercent,
          imageUrl: result.imageUrl,
        );
      }
    } catch (_) {
      // The external site may throttle or block automated requests.
      // The app remains usable and can fall back to the bundled demo catalog.
    }

    if (!allowDemoFallback) return null;
    return DemoCardProvider.find(
      normalized,
      discountPercent: discountPercent,
    );
  }
}

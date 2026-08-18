import 'package:flutter_test/flutter_test.dart';
import 'package:manaprice_br/data/datasources/ligamagic_browser_client.dart';
import 'package:manaprice_br/data/datasources/ligamagic_scrape_client.dart';
import 'package:manaprice_br/data/datasources/ligamagic_scrape_parser.dart';
import 'package:manaprice_br/data/datasources/price_source.dart';
import 'package:manaprice_br/data/datasources/scryfall_catalog_client.dart';
import 'package:manaprice_br/data/providers/card_price_provider.dart';

class _FakeCatalog extends ScryfallCatalogClient {
  _FakeCatalog();

  @override
  Future<ScryfallCatalogCard?> find(String query) async {
    if (query.toLowerCase().contains('testemunha')) {
      return const ScryfallCatalogCard(
        name: 'Eternal Witness',
        displayName: 'Testemunha Eterna',
        imageUrl: 'https://catalog.example/eternal-witness.jpg',
      );
    }
    return null;
  }
}

class _FakeLigaClient extends LigaMagicScrapeClient {
  _FakeLigaClient({this.result});
  final LigaMagicScrapeResult? result;

  @override
  Future<LigaMagicScrapeResult?> lookup(PriceLookupRequest request) async => result;
}

class _FakeBrowserClient extends LigaMagicBrowserClient {
  const _FakeBrowserClient();

  @override
  Future<LigaMagicScrapeResult?> lookup(PriceLookupRequest request) async => null;
}

void main() {
  group('CardPriceProvider regressions', () {
    test('resolves Portuguese display name to canonical English name', () async {
      final provider = CardPriceProvider(
        client: _FakeLigaClient(),
        browserClient: const _FakeBrowserClient(),
        catalogClient: _FakeCatalog(),
      );

      final item = await provider.find('Testemunha Eterna');

      expect(item, isNotNull);
      expect(item!.cardName, 'Eternal Witness');
      expect(item.imageUrl, 'https://catalog.example/eternal-witness.jpg');
    });

    test('catalog image wins over LigaMagic scraped image', () async {
      final result = LigaMagicScrapeResult(
        response: const PriceLookupResponse(
          cardName: 'Eternal Witness',
          referencePrice: 12.50,
        ),
        imageUrl: 'https://ligamagic.example/wrong-or-generic.jpg',
        visuallyVerified: true,
      );
      final provider = CardPriceProvider(
        client: _FakeLigaClient(result: result),
        browserClient: const _FakeBrowserClient(),
        catalogClient: _FakeCatalog(),
      );

      final item = await provider.find('Testemunha Eterna');

      expect(item, isNotNull);
      expect(item!.referencePrice, 12.50);
      expect(item.imageUrl, 'https://catalog.example/eternal-witness.jpg');
    });
  });
}

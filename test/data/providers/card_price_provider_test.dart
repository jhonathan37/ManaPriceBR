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
  PriceLookupRequest? lastRequest;

  @override
  Future<LigaMagicScrapeResult?> lookup(PriceLookupRequest request) async {
    lastRequest = request;
    return result;
  }
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
      expect(item.displayName, 'Testemunha Eterna');
      expect(item.visibleName, 'Testemunha Eterna');
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
      expect(item.visibleName, 'Testemunha Eterna');
      expect(item.imageUrl, 'https://catalog.example/eternal-witness.jpg');
    });

    test('Portuguese lookup keeps catalog image and LigaMagic price together', () async {
      final liga = _FakeLigaClient(
        result: LigaMagicScrapeResult(
          response: const PriceLookupResponse(
            cardName: 'Eternal Witness',
            referencePrice: 27.90,
          ),
          imageUrl: null,
          visuallyVerified: true,
          editionCode: '2XM',
          averagePrice: 31.50,
          maximumPrice: 39.90,
        ),
      );
      final provider = CardPriceProvider(
        client: liga,
        browserClient: const _FakeBrowserClient(),
        catalogClient: _FakeCatalog(),
      );

      final item = await provider.find(
        'Testemunha Eterna',
        setCode: '2XM',
        setName: 'Double Masters',
        collectorNumber: '167',
        condition: 'NM',
        foil: false,
      );

      expect(item, isNotNull);
      expect(item!.cardName, 'Eternal Witness');
      expect(item.displayName, 'Testemunha Eterna');
      expect(item.visibleName, 'Testemunha Eterna');
      expect(item.referencePrice, 27.90);
      expect(item.imageUrl, 'https://catalog.example/eternal-witness.jpg');
      expect(item.editionCode, '2XM');
      expect(item.averagePrice, 31.50);
      expect(item.maximumPrice, 39.90);
      expect(item.priceVerified, isTrue);
      expect(liga.lastRequest, isNotNull);
      expect(liga.lastRequest!.cardName, 'Eternal Witness');
      expect(liga.lastRequest!.setCode, '2XM');
      expect(liga.lastRequest!.collectorNumber, '167');
      expect(liga.lastRequest!.condition, 'NM');
      expect(liga.lastRequest!.foil, isFalse);
    });
  });
}

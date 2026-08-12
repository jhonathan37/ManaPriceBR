import 'package:flutter_test/flutter_test.dart';
import 'package:manaprice_br/data/datasources/ligamagic_scrape_parser.dart';
import 'package:manaprice_br/data/datasources/price_source.dart';

void main() {
  group('LigaMagicScrapeParser', () {
    test('returns the lowest BRL price near the requested card name', () {
      const html = '''
        <html><body>
          <section>
            <h1>The One Ring</h1>
            <div>R\$ 329,90</div>
            <div>R\$ 299,99</div>
            <div>R\$ 315,00</div>
          </section>
        </body></html>
      ''';

      final result = LigaMagicScrapeParser.parse(
        request: const PriceLookupRequest(cardName: 'The One Ring'),
        html: html,
      );

      expect(result, isNotNull);
      expect(result!.response.referencePrice, 299.99);
    });

    test('ignores unrelated prices far from the requested card block', () {
      const html = '''
        <html><body>
          <div>Black Lotus R\$ 1,00</div>
          <section>
            <h1>Sol Ring</h1>
            <div>R\$ 12,50</div>
            <div>R\$ 9,90</div>
          </section>
        </body></html>
      ''';

      final result = LigaMagicScrapeParser.parse(
        request: const PriceLookupRequest(cardName: 'Sol Ring'),
        html: html,
      );

      expect(result, isNotNull);
      expect(result!.response.referencePrice, 9.90);
    });

    test('returns null when no BRL price is found for the card', () {
      const html = '<html><body><h1>Counterspell</h1><div>Sem estoque</div></body></html>';

      final result = LigaMagicScrapeParser.parse(
        request: const PriceLookupRequest(cardName: 'Counterspell'),
        html: html,
      );

      expect(result, isNull);
    });
  });
}

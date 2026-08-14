import 'package:flutter_test/flutter_test.dart';
import 'package:manaprice_br/data/datasources/ligamagic_scrape_parser.dart';
import 'package:manaprice_br/data/datasources/price_source.dart';

void main() {
  group('LigaMagicScrapeParser', () {
    test('reads cardsjson price but marks it unverified without visible offer', () {
      const html = '''
        <html><body>
          <script>
            var cardsjson = [
              {"nEN":"Sol Ring","nPT":"Anel Solar","p1a":"12,50"},
              {"nEN":"Sol Ring","nPT":"Anel Solar","p1a":"9,90"},
              {"nEN":"Black Lotus","nPT":"Lótus Preto","p1a":"1,00"}
            ];
          </script>
        </body></html>
      ''';

      final result = LigaMagicScrapeParser.parse(
        request: const PriceLookupRequest(cardName: 'Sol Ring'),
        html: html,
      );

      expect(result, isNotNull);
      expect(result!.response.referencePrice, 9.90);
      expect(result.visuallyVerified, isFalse);
    });

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
      expect(result.visuallyVerified, isTrue);
    });

    test('rejects a structured price that is 100x below the visible offer', () {
      const html = '''
        <html><body>
          <script>
            var cardsjson = [
              {"nEN":"The Soul Stone","nPT":"The Soul Stone","p1a":"4.95"}
            ];
          </script>
          <section>
            <h1>The Soul Stone</h1>
            <div>R\$ 495,00</div>
          </section>
        </body></html>
      ''';

      final result = LigaMagicScrapeParser.parse(
        request: const PriceLookupRequest(cardName: 'The Soul Stone'),
        html: html,
      );

      expect(result, isNotNull);
      expect(result!.response.referencePrice, 495.00);
      expect(result.visuallyVerified, isTrue);
    });

    test('keeps the true lower price when structured and visible values agree', () {
      const html = '''
        <html><body>
          <script>
            var cardsjson = [
              {"nEN":"Tony Stark","nPT":"Tony Stark","p1a":"89,90"}
            ];
          </script>
          <section>
            <h1>Tony Stark</h1>
            <div>R\$ 94,90</div>
          </section>
        </body></html>
      ''';

      final result = LigaMagicScrapeParser.parse(
        request: const PriceLookupRequest(cardName: 'Tony Stark'),
        html: html,
      );

      expect(result, isNotNull);
      expect(result!.response.referencePrice, 89.90);
      expect(result.visuallyVerified, isTrue);
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
      expect(result.visuallyVerified, isTrue);
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

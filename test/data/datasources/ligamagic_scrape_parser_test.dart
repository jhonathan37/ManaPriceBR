import 'package:flutter_test/flutter_test.dart';
import 'package:manaprice_br/data/datasources/ligamagic_scrape_parser.dart';
import 'package:manaprice_br/data/datasources/price_source.dart';

void main() {
  group('LigaMagicScrapeParser', () {
    test('reads minimum average and maximum from cards_editions', () {
      const html = '''<script>
      var cards_editions = [
        {"code":"SLD","price":{"0":{"p":"495,00","m":"520,00","g":"599,90"}}}
      ];
      </script>''';
      final result = LigaMagicScrapeParser.parse(
        request: const PriceLookupRequest(cardName: 'The Soul Stone', setCode: 'SLD'),
        html: html,
      );
      expect(result, isNotNull);
      expect(result!.response.referencePrice, 495.00);
      expect(result.averagePrice, 520.00);
      expect(result.maximumPrice, 599.90);
      expect(result.editionCode, 'SLD');
      expect(result.visuallyVerified, isTrue);
    });

    test('selects exact edition instead of a cheaper neighboring edition', () {
      const html = '''<script>
      var cards_editions = [
        {"code":"AAA","price":{"0":{"p":"4,95","m":"6,00","g":"8,00"}}},
        {"code":"SLD","price":{"0":{"p":"495,00","m":"520,00","g":"599,90"}}}
      ];
      </script>''';
      final result = LigaMagicScrapeParser.parse(
        request: const PriceLookupRequest(cardName: 'The Soul Stone', setCode: 'SLD'),
        html: html,
      );
      expect(result, isNotNull);
      expect(result!.response.referencePrice, 495.00);
      expect(result.editionCode, 'SLD');
    });

    test('without edition uses lowest structured Liga minimum', () {
      const html = '''<script>
      var cards_editions = [
        {"code":"SET1","price":{"0":{"p":"19,90","m":"25,00","g":"30,00"}}},
        {"code":"SET2","price":{"0":{"p":"12,50","m":"15,00","g":"20,00"}}}
      ];
      </script>''';
      final result = LigaMagicScrapeParser.parse(
        request: const PriceLookupRequest(cardName: 'Sol Ring'),
        html: html,
      );
      expect(result, isNotNull);
      expect(result!.response.referencePrice, 12.50);
      expect(result.editionCode, 'SET2');
    });

    test('foil does not guess an unidentified structured price entry', () {
      const html = '''<script>
      var cards_editions = [
        {"code":"SET","price":{"0":{"p":"10,00"},"1":{"p":"100,00"}}}
      ];
      </script>''';
      final result = LigaMagicScrapeParser.parse(
        request: const PriceLookupRequest(cardName: 'Tony Stark', foil: true),
        html: html,
      );
      expect(result, isNull);
    });

    test('cardsjson alone stays unverified', () {
      const html = '''<script>var cardsjson=[{"nEN":"The Soul Stone","p1a":"4.95"}];</script>''';
      final result = LigaMagicScrapeParser.parse(
        request: const PriceLookupRequest(cardName: 'The Soul Stone'), html: html);
      expect(result, isNotNull);
      expect(result!.response.referencePrice, 4.95);
      expect(result.visuallyVerified, isFalse);
    });

    test('Soul Stone visible offer wins over misleading cardsjson', () {
      const html = '''
      <script>var cardsjson=[{"nEN":"The Soul Stone","p1a":"4.95"}];</script>
      <section><h1>The Soul Stone</h1><div>R\$ 495,00</div></section>''';
      final result = LigaMagicScrapeParser.parse(
        request: const PriceLookupRequest(cardName: 'The Soul Stone'), html: html);
      expect(result, isNotNull);
      expect(result!.response.referencePrice, 495.00);
      expect(result.visuallyVerified, isTrue);
    });

    test('does not grab a cheap price from a neighboring offer', () {
      const html = '''
      <section><h1>The Soul Stone</h1><div>R\$ 495,00</div></section>
      <section><h1>Token</h1><div>R\$ 4,95</div></section>''';
      final result = LigaMagicScrapeParser.parse(
        request: const PriceLookupRequest(cardName: 'The Soul Stone'), html: html);
      expect(result!.response.referencePrice, 495.00);
    });

    test('filters edition, condition and foil inside visible offer block', () {
      const html = '''
      <section><h1>Tony Stark</h1><span>Marvel Test Set</span><span>#123</span><span>NM</span><span>Foil</span><div>R\$ 299,90</div></section>
      <section><h1>Tony Stark</h1><span>Other Set</span><span>#999</span><span>NM</span><span>Foil</span><div>R\$ 19,90</div></section>''';
      final result = LigaMagicScrapeParser.parse(
        request: const PriceLookupRequest(cardName: 'Tony Stark', setName: 'Marvel Test Set', collectorNumber: '#123', condition: 'NM', foil: true), html: html);
      expect(result, isNotNull);
      expect(result!.response.referencePrice, 299.90);
    });

    test('returns null when no visible or structured price exists', () {
      const html = '<section><h1>Counterspell</h1><div>Sem estoque</div></section>';
      final result = LigaMagicScrapeParser.parse(
        request: const PriceLookupRequest(cardName: 'Counterspell'), html: html);
      expect(result, isNull);
    });
  });
}

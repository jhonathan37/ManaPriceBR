import 'package:flutter_test/flutter_test.dart';
import 'package:manaprice_br/data/datasources/ligamagic_url_builder.dart';
import 'package:manaprice_br/data/datasources/price_source.dart';

void main() {
  group('LigaMagicUrlBuilder', () {
    test('builds the real card route by name', () {
      final uri = LigaMagicUrlBuilder.card(
        const PriceLookupRequest(cardName: 'Sol Ring'),
      );

      expect(uri.host, 'www.ligamagic.com.br');
      expect(uri.queryParameters['view'], 'cards/card');
      expect(uri.queryParameters['card'], 'Sol Ring');
    });

    test('builds the real search route by name', () {
      final uri = LigaMagicUrlBuilder.search(
        const PriceLookupRequest(cardName: 'The One Ring'),
      );

      expect(uri.queryParameters['view'], 'cards/search');
      expect(uri.queryParameters['card'], 'The One Ring');
    });

    test('uses the front face for double-faced cards', () {
      final uri = LigaMagicUrlBuilder.card(
        const PriceLookupRequest(cardName: 'Delver of Secrets // Insectile Aberration'),
      );

      expect(uri.queryParameters['card'], 'Delver of Secrets');
    });
  });
}

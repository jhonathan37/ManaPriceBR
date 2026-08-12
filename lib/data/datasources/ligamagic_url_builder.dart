import 'price_source.dart';

class LigaMagicUrlBuilder {
  const LigaMagicUrlBuilder._();

  static Uri card(PriceLookupRequest request) {
    return Uri.https(
      'www.ligamagic.com.br',
      '/',
      {
        'view': 'cards/card',
        'card': _frontFace(request.cardName),
      },
    );
  }

  static Uri search(PriceLookupRequest request) {
    return Uri.https(
      'www.ligamagic.com.br',
      '/',
      {
        'view': 'cards/search',
        'card': _frontFace(request.cardName),
      },
    );
  }

  static Uri build(PriceLookupRequest request) => card(request);

  static String _frontFace(String name) {
    final index = name.indexOf(' // ');
    return (index >= 0 ? name.substring(0, index) : name).trim();
  }
}

import 'price_source.dart';

/// Builds the external search target used by the price integration.
/// The exact response parser remains isolated from URL construction so it can
/// be changed without touching the presentation layer.
class LigaMagicUrlBuilder {
  const LigaMagicUrlBuilder._();

  static Uri build(PriceLookupRequest request) {
    final query = <String, String>{
      'q': request.cardName,
      'language': request.language,
      'condition': request.condition,
      'foil': request.foil ? '1' : '0',
    };

    return Uri.https('www.ligamagic.com.br', '/', query);
  }
}

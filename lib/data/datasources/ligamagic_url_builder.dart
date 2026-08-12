import 'price_source.dart';

class LigaMagicUrlBuilder {
  const LigaMagicUrlBuilder._();

  static Uri build(PriceLookupRequest request) {
    final query = <String, String>{
      'q': request.cardName,
      'language': request.language,
      'condition': request.condition,
      'foil': request.foil ? '1' : '0',
      if (request.setCode != null && request.setCode!.isNotEmpty)
        'set': request.setCode!,
      if (request.setName != null && request.setName!.isNotEmpty)
        'edition': request.setName!,
      if (request.collectorNumber != null && request.collectorNumber!.isNotEmpty)
        'collector': request.collectorNumber!,
    };

    return Uri.https('www.ligamagic.com.br', '/', query);
  }
}

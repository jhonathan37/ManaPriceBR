import '../core/services/card_name_parser.dart';
import '../data/datasources/price_source.dart';
import '../domain/entities/price_result.dart';

class SearchCardService {
  const SearchCardService(this.priceSource);

  final PriceSource priceSource;

  Future<PriceResult?> search({
    required String rawCardName,
    String language = 'Português',
    String condition = 'NM',
    bool foil = false,
    double discountPercent = 15,
  }) async {
    final cardName = CardNameParser.clean(rawCardName);
    if (cardName.isEmpty) return null;

    final response = await priceSource.lookup(
      PriceLookupRequest(
        cardName: cardName,
        language: language,
        condition: condition,
        foil: foil,
      ),
    );
    if (response == null) return null;

    final salePrice = response.referencePrice * (1 - discountPercent / 100);
    return PriceResult(
      cardName: response.cardName,
      referencePrice: response.referencePrice,
      discountPercent: discountPercent,
      salePrice: salePrice,
    );
  }
}

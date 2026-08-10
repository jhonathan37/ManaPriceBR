import 'price_source.dart';

class PriceResponseValidator {
  const PriceResponseValidator._();

  static PriceLookupResponse? validate(PriceLookupResponse? response) {
    if (response == null) return null;
    if (response.cardName.trim().isEmpty) return null;
    if (!response.referencePrice.isFinite || response.referencePrice <= 0) return null;
    if (response.sourceName.trim().isEmpty) return null;
    return response;
  }
}

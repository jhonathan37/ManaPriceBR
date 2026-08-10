class PriceLookupRequest {
  const PriceLookupRequest({
    required this.cardName,
    this.language = 'Português',
    this.condition = 'NM',
    this.foil = false,
  });

  final String cardName;
  final String language;
  final String condition;
  final bool foil;
}

class PriceLookupResponse {
  const PriceLookupResponse({
    required this.cardName,
    required this.referencePrice,
    this.sourceName = 'Liga Magic',
  });

  final String cardName;
  final double referencePrice;
  final String sourceName;
}

abstract interface class PriceSource {
  Future<PriceLookupResponse?> lookup(PriceLookupRequest request);
}

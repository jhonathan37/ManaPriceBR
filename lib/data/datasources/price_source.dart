class PriceLookupRequest {
  const PriceLookupRequest({
    required this.cardName,
    this.setCode,
    this.setName,
    this.collectorNumber,
    this.language = 'Português',
    this.condition = 'NM',
    this.foil = false,
  });

  final String cardName;
  final String? setCode;
  final String? setName;
  final String? collectorNumber;
  final String language;
  final String condition;
  final bool foil;

  bool get hasExactPrinting =>
      setCode != null && setCode!.isNotEmpty &&
      collectorNumber != null && collectorNumber!.isNotEmpty;
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

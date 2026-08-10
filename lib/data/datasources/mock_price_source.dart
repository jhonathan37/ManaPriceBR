import 'price_source.dart';

/// Temporary source used while the real market-price integration is being built.
/// It keeps the UI and domain layers testable without pretending this is live data.
class MockPriceSource implements PriceSource {
  const MockPriceSource();

  @override
  Future<PriceLookupResponse?> lookup(PriceLookupRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (request.cardName.trim().isEmpty) return null;

    return PriceLookupResponse(
      cardName: request.cardName.trim(),
      referencePrice: 0,
      sourceName: 'Aguardando integração de preços',
    );
  }
}

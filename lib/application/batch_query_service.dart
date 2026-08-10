import '../data/datasources/batch_price_service.dart';
import '../data/datasources/price_source.dart';

class BatchQueryService {
  const BatchQueryService(this.batchPriceService);

  final BatchPriceService batchPriceService;

  Future<List<PriceLookupResponse>> queryNames({
    required List<String> names,
    String language = 'Português',
    String condition = 'NM',
    bool foil = false,
  }) {
    final requests = names
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .map(
          (name) => PriceLookupRequest(
            cardName: name,
            language: language,
            condition: condition,
            foil: foil,
          ),
        )
        .toList();

    return batchPriceService.lookupAll(requests);
  }
}

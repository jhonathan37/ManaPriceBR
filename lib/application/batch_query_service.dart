import '../core/services/card_name_parser.dart';
import '../data/datasources/price_source.dart';
import '../data/datasources/batch_price_service.dart';
import '../domain/entities/batch_item.dart';
import '../domain/entities/price_result.dart';

class BatchQueryService {
  const BatchQueryService(this.batchPriceService);

  final BatchPriceService batchPriceService;

  Future<List<BatchItem>> execute({
    required List<String> names,
    String language = 'Português',
    String condition = 'NM',
    bool foil = false,
    double discountPercent = 15,
  }) async {
    final cleaned = <String>{
      for (final raw in names)
        if (CardNameParser.clean(raw).isNotEmpty) CardNameParser.clean(raw),
    }.toList();

    final requests = cleaned
        .map((name) => PriceLookupRequest(
              cardName: name,
              language: language,
              condition: condition,
              foil: foil,
            ))
        .toList();

    final results = await batchPriceService.lookupAll(requests);
    final byName = {for (final result in results) result.cardName.toLowerCase(): result};

    return cleaned.map((name) {
      final response = byName[name.toLowerCase()];
      if (response == null) {
        return BatchItem(name: name, error: 'Preço não encontrado');
      }
      final salePrice = response.referencePrice * (1 - discountPercent / 100);
      return BatchItem(
        name: name,
        result: PriceResult(
          cardName: response.cardName,
          referencePrice: response.referencePrice,
          discountPercent: discountPercent,
          salePrice: salePrice,
          currency: 'BRL',
        ),
      );
    }).toList();
  }
}

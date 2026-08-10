import '../../domain/entities/batch_item.dart';
import 'sale_summary.dart';

class BatchSaleCalculator {
  const BatchSaleCalculator._();

  static SaleSummary calculate(List<BatchItem> items) {
    var referenceTotal = 0.0;
    var saleTotal = 0.0;
    var found = 0;
    var missing = 0;

    for (final item in items) {
      final result = item.result;
      if (result == null) {
        missing++;
        continue;
      }
      found++;
      referenceTotal += result.referencePrice;
      saleTotal += result.salePrice;
    }

    return SaleSummary(
      referenceTotal: referenceTotal,
      saleTotal: saleTotal,
      cardsFound: found,
      cardsMissing: missing,
    );
  }
}

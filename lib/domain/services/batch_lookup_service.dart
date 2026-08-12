import '../entities/batch_card_request.dart';
import '../entities/batch_lookup_result.dart';
import '../entities/sale_item.dart';
import 'batch_lookup_runner.dart';

class BatchLookupService {
  const BatchLookupService({this.runner = const BatchLookupRunner()});

  final BatchLookupRunner runner;

  Future<BatchLookupResult> lookup(
    BatchCardRequest request, {
    required Future<SaleItem?> Function(String cardName) findCard,
    void Function(int completed, int total)? onProgress,
  }) async {
    final items = <SaleItem>[];
    final failed = <String>[];

    await runner.run(
      request,
      lookup: (name) async {
        final item = await findCard(name);
        if (item == null) {
          failed.add(name);
          return false;
        }
        items.add(item);
        return true;
      },
      onProgress: (progress) => onProgress?.call(progress.completed, progress.total),
    );

    return BatchLookupResult(items: items, failedNames: failed);
  }
}

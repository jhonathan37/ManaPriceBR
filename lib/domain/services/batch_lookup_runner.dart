import '../entities/batch_card_request.dart';
import '../entities/batch_lookup_progress.dart';

class BatchLookupRunner {
  const BatchLookupRunner({this.maxConcurrent = 5});

  final int maxConcurrent;

  Future<BatchLookupProgress> run(
    BatchCardRequest request, {
    required Future<bool> Function(String cardName) lookup,
    void Function(BatchLookupProgress progress)? onProgress,
  }) async {
    final names = request.normalizedNames;
    if (names.isEmpty) {
      const empty = BatchLookupProgress(
        total: 0,
        completed: 0,
        successful: 0,
        failed: 0,
      );
      onProgress?.call(empty);
      return empty;
    }

    final concurrency = maxConcurrent.clamp(1, names.length);
    var cursor = 0;
    var completed = 0;
    var successful = 0;
    var failed = 0;

    Future<void> worker() async {
      while (true) {
        if (cursor >= names.length) return;
        final index = cursor++;
        final name = names[index];
        bool found;
        try {
          found = await lookup(name);
        } catch (_) {
          found = false;
        }

        completed++;
        if (found) {
          successful++;
        } else {
          failed++;
        }
        onProgress?.call(BatchLookupProgress(
          total: names.length,
          completed: completed,
          successful: successful,
          failed: failed,
        ));
      }
    }

    await Future.wait(List.generate(concurrency, (_) => worker()));

    return BatchLookupProgress(
      total: names.length,
      completed: completed,
      successful: successful,
      failed: failed,
    );
  }
}

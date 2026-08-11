import '../../domain/entities/batch_progress.dart';

class BatchProgressTracker {
  BatchProgressTracker(int total) : _total = total < 0 ? 0 : total;

  final int _total;
  int _completed = 0;
  int _found = 0;

  BatchProgress get current => BatchProgress(
        total: _total,
        completed: _completed,
        found: _found,
      );

  void markFound() {
    if (_completed >= _total) return;
    _completed++;
    _found++;
  }

  void markMissing() {
    if (_completed >= _total) return;
    _completed++;
  }
}

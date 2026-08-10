class RequestLimiter {
  RequestLimiter({this.maxConcurrent = 3});

  final int maxConcurrent;
  int _active = 0;
  final List<Future<void> Function()> _queue = [];

  Future<T> run<T>(Future<T> Function() task) {
    final completer = _TaskCompleter<T>();
    _queue.add(() async {
      try {
        completer.complete(await task());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    _drain();
    return completer.future;
  }

  void _drain() {
    while (_active < maxConcurrent && _queue.isNotEmpty) {
      final task = _queue.removeAt(0);
      _active++;
      task().whenComplete(() {
        _active--;
        _drain();
      });
    }
  }
}

class _TaskCompleter<T> {
  final _completer = Completer<T>();
  Future<T> get future => _completer.future;
  void complete(T value) => _completer.complete(value);
  void completeError(Object error, StackTrace stackTrace) => _completer.completeError(error, stackTrace);
}

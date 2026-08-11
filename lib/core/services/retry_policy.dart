class RetryPolicy {
  const RetryPolicy({
    this.maxAttempts = 3,
    this.baseDelay = const Duration(milliseconds: 800),
  });

  final int maxAttempts;
  final Duration baseDelay;

  Duration delayFor(int attempt) {
    final safeAttempt = attempt < 1 ? 1 : attempt;
    return Duration(milliseconds: baseDelay.inMilliseconds * safeAttempt);
  }

  bool shouldRetry(int statusCode) {
    return statusCode == 408 || statusCode == 429 || statusCode >= 500;
  }
}

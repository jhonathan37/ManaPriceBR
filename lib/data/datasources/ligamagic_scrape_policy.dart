class LigaMagicScrapePolicy {
  const LigaMagicScrapePolicy({
    this.maxConcurrent = 5,
    this.delayBetweenRequests = const Duration(milliseconds: 300),
    this.delayBetweenBatches = const Duration(seconds: 1),
    this.timeout = const Duration(seconds: 30),
    this.maxRetries = 2,
  });

  final int maxConcurrent;
  final Duration delayBetweenRequests;
  final Duration delayBetweenBatches;
  final Duration timeout;
  final int maxRetries;

  LigaMagicScrapePolicy normalized() {
    return LigaMagicScrapePolicy(
      maxConcurrent: maxConcurrent.clamp(1, 5),
      delayBetweenRequests: delayBetweenRequests < Duration.zero
          ? Duration.zero
          : delayBetweenRequests,
      delayBetweenBatches: delayBetweenBatches < Duration.zero
          ? Duration.zero
          : delayBetweenBatches,
      timeout: timeout <= Duration.zero ? const Duration(seconds: 30) : timeout,
      maxRetries: maxRetries.clamp(0, 5),
    );
  }
}

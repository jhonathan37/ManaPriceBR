class LigaMagicScrapeHealth {
  const LigaMagicScrapeHealth({
    required this.successes,
    required this.failures,
    required this.rateLimited,
    required this.lastError,
  });

  final int successes;
  final int failures;
  final int rateLimited;
  final String? lastError;

  bool get isHealthy => failures == 0 || successes >= failures * 3;

  LigaMagicScrapeHealth recordSuccess() => LigaMagicScrapeHealth(
        successes: successes + 1,
        failures: failures,
        rateLimited: rateLimited,
        lastError: lastError,
      );

  LigaMagicScrapeHealth recordFailure(String error, {bool rateLimit = false}) => LigaMagicScrapeHealth(
        successes: successes,
        failures: failures + 1,
        rateLimited: rateLimited + (rateLimit ? 1 : 0),
        lastError: error,
      );
}

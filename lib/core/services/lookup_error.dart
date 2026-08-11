enum LookupErrorType {
  timeout,
  rateLimited,
  server,
  invalidResponse,
  network,
  notFound,
}

class LookupError {
  const LookupError(this.type, this.message);

  final LookupErrorType type;
  final String message;
}

class BatchLookupProgress {
  const BatchLookupProgress({
    required this.total,
    required this.completed,
    required this.successful,
    required this.failed,
  });

  final int total;
  final int completed;
  final int successful;
  final int failed;

  double get percentage => total == 0 ? 0 : completed / total;

  bool get isComplete => total > 0 && completed >= total;
}

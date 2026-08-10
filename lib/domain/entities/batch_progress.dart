class BatchProgress {
  const BatchProgress({
    required this.total,
    required this.completed,
    required this.found,
  });

  final int total;
  final int completed;
  final int found;

  int get missing => completed - found;
  double get fraction => total == 0 ? 0 : (completed / total).clamp(0, 1);
}

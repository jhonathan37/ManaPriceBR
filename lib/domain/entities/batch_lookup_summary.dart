class BatchLookupSummary {
  const BatchLookupSummary({
    required this.total,
    required this.found,
    required this.missing,
    required this.referenceTotal,
    required this.saleTotal,
  });

  final int total;
  final int found;
  final int missing;
  final double referenceTotal;
  final double saleTotal;

  double get savings => referenceTotal - saleTotal;
  double get completion => total == 0 ? 0 : found / total;
}

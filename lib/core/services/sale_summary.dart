class SaleSummary {
  const SaleSummary({
    required this.referenceTotal,
    required this.saleTotal,
    required this.cardsFound,
    required this.cardsMissing,
  });

  final double referenceTotal;
  final double saleTotal;
  final int cardsFound;
  final int cardsMissing;

  double get discountTotal => referenceTotal - saleTotal;
}

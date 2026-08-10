class PriceCalculator {
  const PriceCalculator._();

  static double salePrice({
    required double referencePrice,
    required double discountPercent,
  }) {
    final discount = discountPercent.clamp(0, 100) / 100;
    return referencePrice * (1 - discount);
  }

  static double discountAmount({
    required double referencePrice,
    required double discountPercent,
  }) {
    return referencePrice - salePrice(
      referencePrice: referencePrice,
      discountPercent: discountPercent,
    );
  }
}

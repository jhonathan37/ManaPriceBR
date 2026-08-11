class SaleCalculator {
  const SaleCalculator._();

  static double finalValue(double referencePrice, double discountPercent) {
    final safePrice = referencePrice.isFinite && referencePrice > 0 ? referencePrice : 0;
    final safeDiscount = discountPercent.isFinite ? discountPercent.clamp(0, 100) : 0;
    return safePrice * (1 - safeDiscount / 100);
  }

  static double discountAmount(double referencePrice, double discountPercent) {
    return referencePrice - finalValue(referencePrice, discountPercent);
  }
}

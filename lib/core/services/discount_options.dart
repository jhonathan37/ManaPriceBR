class DiscountOptions {
  const DiscountOptions._();

  static double normalize(double value) {
    if (value.isNaN || !value.isFinite) return 0;
    return value.clamp(0, 100).toDouble();
  }

  static double salePrice(double referencePrice, double discountPercent) {
    final discount = normalize(discountPercent) / 100;
    return referencePrice * (1 - discount);
  }
}

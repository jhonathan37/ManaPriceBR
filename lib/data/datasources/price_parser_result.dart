class PriceParserResult {
  const PriceParserResult({required this.value, required this.confidence});

  final double value;
  final double confidence;

  bool get isReliable => value.isFinite && value > 0 && confidence >= 0.8;
}

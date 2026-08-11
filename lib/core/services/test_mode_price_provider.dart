class TestModePriceProvider {
  const TestModePriceProvider._();

  static const Map<String, double> samplePrices = {
    'The One Ring': 350.00,
    'Sol Ring': 5.00,
    'Command Tower': 2.50,
  };

  static double? lookup(String cardName) {
    final normalized = cardName.trim().toLowerCase();
    for (final entry in samplePrices.entries) {
      if (entry.key.toLowerCase() == normalized) return entry.value;
    }
    return null;
  }
}

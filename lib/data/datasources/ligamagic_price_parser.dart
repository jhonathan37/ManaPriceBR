class LigaMagicPriceParser {
  const LigaMagicPriceParser._();

  /// Parses a price represented in common Brazilian formats, for example:
  /// R$ 123,45 / 123,45 / 123.45.
  ///
  /// This parser deliberately does not guess which number on an arbitrary HTML
  /// page is a card price. The caller must first isolate the relevant price
  /// element from the source response.
  static double? parsePrice(String value) {
    var text = value.trim().replaceAll('R\$', '').replaceAll(' ', '');
    if (text.isEmpty) return null;

    if (text.contains(',') && text.contains('.')) {
      text = text.replaceAll('.', '').replaceAll(',', '.');
    } else if (text.contains(',')) {
      text = text.replaceAll(',', '.');
    }

    return double.tryParse(text);
  }

  static List<double> parseMany(Iterable<String> values) {
    return values.map(parsePrice).whereType<double>().where((v) => v >= 0).toList();
  }

  static double? minimum(Iterable<double> prices) {
    final valid = prices.where((p) => p >= 0).toList();
    if (valid.isEmpty) return null;
    return valid.reduce((a, b) => a < b ? a : b);
  }
}

import 'price_source.dart';

class PriceParser {
  const PriceParser._();

  static PriceLookupResponse? parse({
    required String cardName,
    required String body,
  }) {
    final prices = <double>[];
    final money = RegExp(r'R\$\s*([0-9]{1,6}(?:\.[0-9]{3})*,[0-9]{2}|[0-9]+(?:\.[0-9]{2}))');

    for (final match in money.allMatches(body)) {
      final raw = match.group(1);
      if (raw == null) continue;
      final normalized = raw.contains(',')
          ? raw.replaceAll('.', '').replaceAll(',', '.')
          : raw;
      final value = double.tryParse(normalized);
      if (value != null && value > 0) prices.add(value);
    }

    if (prices.isEmpty) return null;

    prices.sort();
    return PriceLookupResponse(
      cardName: cardName,
      referencePrice: prices.first,
      sourceName: 'Liga Magic',
    );
  }
}

import 'price_filter.dart';

class PriceLookupKey {
  const PriceLookupKey({required this.cardName, required this.filter});

  final String cardName;
  final PriceFilter filter;

  String get value => '${cardName.trim().toLowerCase()}|${filter.language}|${filter.condition}|${filter.foil}';
}

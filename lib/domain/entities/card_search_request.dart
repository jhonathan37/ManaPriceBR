import 'price_filter.dart';

class CardSearchRequest {
  const CardSearchRequest({
    required this.cardName,
    this.filter = const PriceFilter(),
  });

  final String cardName;
  final PriceFilter filter;

  bool get isValid => cardName.trim().isNotEmpty;

  CardSearchRequest copyWith({
    String? cardName,
    PriceFilter? filter,
  }) {
    return CardSearchRequest(
      cardName: cardName ?? this.cardName,
      filter: filter ?? this.filter,
    );
  }
}

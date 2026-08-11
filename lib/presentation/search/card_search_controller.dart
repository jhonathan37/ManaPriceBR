import '../../domain/entities/card_search_request.dart';
import '../../domain/entities/price_filter.dart';
import 'card_search_state.dart';

class CardSearchController {
  CardSearchState state = const CardSearchIdle();

  CardSearchRequest buildRequest({
    required String cardName,
    String language = 'Português',
    String condition = 'NM',
    bool foil = false,
  }) {
    return CardSearchRequest(
      cardName: cardName.trim(),
      filter: PriceFilter(
        language: language,
        condition: condition,
        foil: foil,
      ),
    );
  }

  void begin(CardSearchRequest request) {
    if (request.cardName.trim().isEmpty) {
      state = CardSearchFailure(request, 'Digite o nome da carta.');
      return;
    }
    state = CardSearchLoading(request);
  }

  void succeed({required CardSearchRequest request, required String cardName, required double referencePrice, String? imageUrl}) {
    state = CardSearchSuccess(
      request: request,
      cardName: cardName,
      referencePrice: referencePrice,
      imageUrl: imageUrl,
    );
  }

  void fail(CardSearchRequest request, String message) {
    state = CardSearchFailure(request, message);
  }
}

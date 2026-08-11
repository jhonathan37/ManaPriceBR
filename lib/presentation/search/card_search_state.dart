import '../../domain/entities/card_search_request.dart';

sealed class CardSearchState {
  const CardSearchState();
}

class CardSearchIdle extends CardSearchState {
  const CardSearchIdle();
}

class CardSearchLoading extends CardSearchState {
  const CardSearchLoading(this.request);
  final CardSearchRequest request;
}

class CardSearchSuccess extends CardSearchState {
  const CardSearchSuccess({required this.request, required this.cardName, required this.referencePrice, this.imageUrl});

  final CardSearchRequest request;
  final String cardName;
  final double referencePrice;
  final String? imageUrl;
}

class CardSearchFailure extends CardSearchState {
  const CardSearchFailure(this.request, this.message);
  final CardSearchRequest request;
  final String message;
}

enum PriceQueryStrategy {
  ligaMagicDirect,
  fallbackApi,
}

class PriceQueryPlan {
  const PriceQueryPlan({required this.strategy, required this.cardName});

  final PriceQueryStrategy strategy;
  final String cardName;
}

class PriceQueryPlanner {
  const PriceQueryPlanner._();

  static PriceQueryPlan create(String cardName) {
    final cleaned = cardName.trim();
    return PriceQueryPlan(
      strategy: PriceQueryStrategy.ligaMagicDirect,
      cardName: cleaned,
    );
  }
}

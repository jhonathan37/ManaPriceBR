import 'price_source.dart';
import 'ligamagic_url_builder.dart';

class LigaMagicRequestPlan {
  const LigaMagicRequestPlan({required this.request, required this.uri});

  final PriceLookupRequest request;
  final Uri uri;
}

class LigaMagicRequestPlanner {
  const LigaMagicRequestPlanner._();

  static LigaMagicRequestPlan create(PriceLookupRequest request) {
    return LigaMagicRequestPlan(
      request: request,
      uri: LigaMagicUrlBuilder.build(request),
    );
  }
}

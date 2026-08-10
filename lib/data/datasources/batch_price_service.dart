import 'price_source.dart';
import 'request_limiter.dart';

class BatchPriceService {
  BatchPriceService({required this.source, RequestLimiter? limiter})
      : limiter = limiter ?? RequestLimiter(maxConcurrent: 3);

  final PriceSource source;
  final RequestLimiter limiter;

  Future<List<PriceLookupResponse>> lookupAll(
    List<PriceLookupRequest> requests,
  ) async {
    final results = await Future.wait(
      requests.map(
        (request) => limiter.run(() => source.lookup(request)),
      ),
    );

    return results.whereType<PriceLookupResponse>().toList();
  }
}

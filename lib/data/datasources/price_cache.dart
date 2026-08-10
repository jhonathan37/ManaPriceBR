import '../../domain/entities/price_result.dart';

class PriceCache {
  PriceCache({this.ttl = const Duration(minutes: 15)});

  final Duration ttl;
  final Map<String, _CachedPrice> _items = {};

  PriceResult? get(String key) {
    final item = _items[key];
    if (item == null || DateTime.now().difference(item.savedAt) > ttl) {
      _items.remove(key);
      return null;
    }
    return item.result;
  }

  void put(String key, PriceResult result) {
    _items[key] = _CachedPrice(result, DateTime.now());
  }

  void clear() => _items.clear();
}

class _CachedPrice {
  const _CachedPrice(this.result, this.savedAt);
  final PriceResult result;
  final DateTime savedAt;
}

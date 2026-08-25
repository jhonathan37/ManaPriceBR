import 'package:hive/hive.dart';

class QuoteHistoryStore {
  static const _boxName = 'quote_history_v1';
  static const _historyKey = 'history';
  static const _favoritesKey = 'favorites';
  static const int maxHistory = 60;

  static Future<Box<dynamic>> _box() => Hive.openBox<dynamic>(_boxName);

  static String idOf(Map<String, dynamic> item) => [
        item['name'] ?? '',
        item['setCode'] ?? '',
        item['collectorNumber'] ?? '',
        item['condition'] ?? 'NM',
        item['foil'] == true ? 'foil' : 'normal',
      ].join('|').toLowerCase();

  static Map<String, dynamic> _clean(Map<String, dynamic> source) => {
        'name': source['name'] as String? ?? '',
        'setCode': source['setCode'] as String?,
        'setName': source['setName'] as String?,
        'collectorNumber': source['collectorNumber'] as String?,
        'imageUrl': source['imageUrl'] as String?,
        'language': source['language'] as String? ?? 'Português',
        'condition': source['condition'] as String? ?? 'NM',
        'foil': source['foil'] as bool? ?? false,
        'savedAt': DateTime.now().millisecondsSinceEpoch,
      };

  static Future<void> add(Map<String, dynamic> filters) async {
    if ((filters['name'] as String? ?? '').trim().isEmpty) return;
    final box = await _box();
    final current = historyFrom(box);
    final item = _clean(filters);
    final id = idOf(item);
    current.removeWhere((e) => idOf(e) == id);
    current.insert(0, item);
    if (current.length > maxHistory) current.removeRange(maxHistory, current.length);
    await box.put(_historyKey, current);
  }

  static List<Map<String, dynamic>> historyFrom(Box<dynamic> box) {
    final raw = box.get(_historyKey, defaultValue: const <dynamic>[]);
    if (raw is! List) return [];
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static List<Map<String, dynamic>> favoritesFrom(Box<dynamic> box) {
    final raw = box.get(_favoritesKey, defaultValue: const <dynamic>[]);
    if (raw is! List) return [];
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<List<Map<String, dynamic>>> history() async => historyFrom(await _box());
  static Future<List<Map<String, dynamic>>> favorites() async => favoritesFrom(await _box());

  static Future<bool> isFavorite(Map<String, dynamic> filters) async {
    final id = idOf(filters);
    return (await favorites()).any((e) => idOf(e) == id);
  }

  static Future<bool> toggleFavorite(Map<String, dynamic> filters) async {
    final box = await _box();
    final list = favoritesFrom(box);
    final item = _clean(filters);
    final id = idOf(item);
    final index = list.indexWhere((e) => idOf(e) == id);
    if (index >= 0) {
      list.removeAt(index);
      await box.put(_favoritesKey, list);
      return false;
    }
    list.insert(0, item);
    await box.put(_favoritesKey, list);
    return true;
  }

  static Future<void> removeHistory(Map<String, dynamic> filters) async {
    final box = await _box();
    final list = historyFrom(box)..removeWhere((e) => idOf(e) == idOf(filters));
    await box.put(_historyKey, list);
  }

  static Future<void> clearHistory() async => (await _box()).delete(_historyKey);
}

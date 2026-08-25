import 'package:hive/hive.dart';

class LifeSessionStore {
  static const _boxName = 'life_session';
  static const _stateKey = 'current';

  Future<Box<dynamic>> _box() => Hive.openBox<dynamic>(_boxName);

  Future<Map<String, dynamic>?> load() async {
    final box = await _box();
    final raw = box.get(_stateKey);
    if (raw is! Map) return null;
    return Map<String, dynamic>.from(raw);
  }

  Future<void> save(Map<String, dynamic> state) async {
    final box = await _box();
    await box.put(_stateKey, state);
  }

  Future<void> clear() async {
    final box = await _box();
    await box.delete(_stateKey);
  }
}

import 'package:hive/hive.dart';

class AppSettings {
  const AppSettings({
    required this.discount,
    required this.language,
    required this.condition,
    required this.foil,
  });

  final double discount;
  final String language;
  final String condition;
  final bool foil;
}

class AppSettingsStore {
  static const _boxName = 'app_settings';

  static Future<Box<dynamic>> _box() => Hive.openBox<dynamic>(_boxName);

  static Future<AppSettings> load() async {
    final box = await _box();
    return AppSettings(
      discount: (box.get('discount', defaultValue: 20) as num).toDouble(),
      language: box.get('language', defaultValue: 'Português') as String,
      condition: box.get('condition', defaultValue: 'NM') as String,
      foil: box.get('foil', defaultValue: false) as bool,
    );
  }

  static Future<void> save(AppSettings settings) async {
    final box = await _box();
    await box.putAll(<String, dynamic>{
      'discount': settings.discount,
      'language': settings.language,
      'condition': settings.condition,
      'foil': settings.foil,
    });
  }
}

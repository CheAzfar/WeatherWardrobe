import 'package:hive/hive.dart';

class CityStore {
  static const String _boxName = 'settingsBox';
  static const String _keyCity = 'city';

  static String getCity() {
    final box = Hive.box(_boxName);
    return (box.get(_keyCity) as String?) ?? 'Kuala Lumpur';
  }

  static Future<void> setCity(String city) async {
    final box = Hive.box(_boxName);
    await box.put(_keyCity, city);
  }
}
